use tauri::Emitter;
use std::process::Command;
use std::sync::Mutex;

// Store sudo password in app state (in-memory only, never persisted)
struct SudoState {
    password: Mutex<Option<String>>,
}

#[tauri::command]
fn verify_password(password: String, state: tauri::State<SudoState>) -> Result<bool, String> {
    // Test the password by running a harmless sudo command
    let output = Command::new("sudo")
        .arg("-S")
        .arg("-v")
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn();

    match output {
        Ok(mut child) => {
            use std::io::Write;
            if let Some(stdin) = child.stdin.as_mut() {
                let _ = stdin.write_all(format!("{}\n", password).as_bytes());
            }
            let status = child.wait().map_err(|e| e.to_string())?;
            if status.success() {
                *state.password.lock().unwrap() = Some(password);
                Ok(true)
            } else {
                Ok(false)
            }
        }
        Err(e) => Err(e.to_string()),
    }
}

#[tauri::command]
async fn install_package(
    script_name: String,
    state: tauri::State<'_, SudoState>,
    window: tauri::Window,
) -> Result<(), String> {
    let password = state.password.lock().unwrap().clone();
    let password = match password {
        Some(p) => p,
        None => return Err("No sudo password set. Please authenticate first.".to_string()),
    };

    let base_url = "https://raw.githubusercontent.com/JaewooJoung/linux/main/";
    let script_url = format!("{}{}", base_url, script_name);

    // Emit start event
    let _ = window.emit("install-output", format!("==> Fetching {}...\n", script_url));

    // Download the script
    let script_output = Command::new("curl")
        .arg("-fsSL")
        .arg(&script_url)
        .output()
        .map_err(|e| format!("Failed to download script: {}", e))?;

    if !script_output.status.success() {
        return Err(format!("Failed to fetch script: {}", script_name));
    }

    let script_content = String::from_utf8_lossy(&script_output.stdout).to_string();

    // Strip shebang only if the script actually has one
    let script_body = {
        let mut lines = script_content.lines();
        let first = lines.next().unwrap_or("");
        if first.starts_with("#!") {
            lines.collect::<Vec<_>>().join("\n")
        } else {
            // No shebang — keep the first line too
            std::iter::once(first)
                .chain(lines)
                .collect::<Vec<_>>()
                .join("\n")
        }
    };

    // Prepend sudo password caching and keep-alive to the script.
    // exec 2>&1 merges stderr into stdout so both streams reach the log panel
    // and the (empty) stderr pipe never blocks.
    let wrapped_script = format!(
        r#"#!/bin/bash
set -e
exec 2>&1
echo '{password}' | sudo -S -v 2>/dev/null
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPER=$!
trap "kill $SUDO_KEEPER 2>/dev/null" EXIT

{script}
"#,
        password = password.replace("'", "'\\''"),
        script = script_body
    );

    let _ = window.emit("install-output", "==> Running installation...\n".to_string());

    // Run the wrapped script
    let mut child = Command::new("bash")
        .arg("-c")
        .arg(&wrapped_script)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .spawn()
        .map_err(|e| format!("Failed to run script: {}", e))?;

    use std::io::{BufRead, BufReader};

    if let Some(stdout) = child.stdout.take() {
        let reader = BufReader::new(stdout);
        for line in reader.lines() {
            if let Ok(line) = line {
                let _ = window.emit("install-output", format!("{}\n", line));
            }
        }
    }

    let status = child.wait().map_err(|e| e.to_string())?;

    if status.success() {
        let _ = window.emit("install-output", "\n✅ Installation complete!\n".to_string());
        Ok(())
    } else {
        Err("Installation failed. Check output for details.".to_string())
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(SudoState {
            password: Mutex::new(None),
        })
        .invoke_handler(tauri::generate_handler![verify_password, install_package])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
