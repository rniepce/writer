use std::process::Command;
use std::path::PathBuf;
use std::io::Write;
use tauri::Manager;

// Store the compile-time path to the backend as a compile-time constant
const DEV_BACKEND_DIR: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../../backend");

fn log_to_file(data_dir: &std::path::Path, msg: &str) {
    let log_file = data_dir.join("zenwriter.log");
    if let Ok(mut f) = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_file)
    {
        let _ = writeln!(f, "[{}] {}", chrono_timestamp(), msg);
    }
}

fn chrono_timestamp() -> String {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    format!("{}", now)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }
      
      // Start the Python backend as a background process
      spawn_backend(app.handle());
      
      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}

/// Find a working Python 3 interpreter on the system.
fn find_system_python(data_dir: &std::path::Path) -> Option<String> {
    let candidates = [
        "/opt/homebrew/bin/python3",
        "/usr/local/bin/python3",
        "/usr/bin/python3",
    ];

    for p in &candidates {
        let exists = std::path::Path::new(p).exists();
        log_to_file(data_dir, &format!("System Python candidate: {} -> exists={}", p, exists));
        if exists {
            return Some(p.to_string());
        }
    }
    None
}

/// Ensure a virtual environment exists in the data directory with all
/// required dependencies installed.  Returns the path to the venv's
/// Python binary, or `None` if bootstrapping failed.
fn ensure_venv(
    data_dir: &std::path::Path,
    working_dir: &std::path::Path,
    system_python: &str,
) -> Option<PathBuf> {
    let venv_dir = data_dir.join("venv");
    let venv_python = venv_dir.join("bin/python");
    let marker = venv_dir.join(".deps_installed");

    // --- Create venv if it doesn't exist ---
    if !venv_python.exists() {
        log_to_file(data_dir, &format!(
            "Creating venv at {:?} with {}", venv_dir, system_python
        ));
        let output = Command::new(system_python)
            .args(["-m", "venv", &venv_dir.to_string_lossy()])
            .output();

        match output {
            Ok(o) if o.status.success() => {
                log_to_file(data_dir, "Venv created successfully");
            }
            Ok(o) => {
                let stderr = String::from_utf8_lossy(&o.stderr);
                log_to_file(data_dir, &format!("Venv creation failed: {}", stderr));
                return None;
            }
            Err(e) => {
                log_to_file(data_dir, &format!("Failed to run python -m venv: {}", e));
                return None;
            }
        }
    }

    // --- Install / update dependencies if marker is missing ---
    if !marker.exists() {
        // First upgrade pip itself (silently)
        let _ = Command::new(venv_python.to_string_lossy().as_ref())
            .args(["-m", "pip", "install", "--upgrade", "pip"])
            .output();

        // Look for requirements.txt – prefer the one next to the backend
        // files (bundled resource dir), fall back to working_dir.
        let req_path = if working_dir.join("requirements.txt").exists() {
            working_dir.join("requirements.txt")
        } else {
            // In dev mode the working_dir IS the backend dir
            working_dir.join("requirements.txt")
        };

        if !req_path.exists() {
            log_to_file(data_dir, &format!(
                "WARNING: requirements.txt not found at {:?} – skipping pip install", req_path
            ));
        } else {
            log_to_file(data_dir, &format!(
                "Installing dependencies from {:?} ...", req_path
            ));
            let output = Command::new(venv_python.to_string_lossy().as_ref())
                .args([
                    "-m", "pip", "install", "-r",
                    &req_path.to_string_lossy(),
                ])
                .output();

            match output {
                Ok(o) if o.status.success() => {
                    log_to_file(data_dir, "Dependencies installed successfully");
                    // Write marker so we skip next time
                    if let Ok(mut f) = std::fs::File::create(&marker) {
                        let _ = writeln!(f, "ok");
                    }
                }
                Ok(o) => {
                    let stderr = String::from_utf8_lossy(&o.stderr);
                    log_to_file(data_dir, &format!(
                        "pip install failed (exit {}): {}", o.status, stderr
                    ));
                    // Don't return None – the venv Python still exists;
                    // maybe some deps were already there.
                }
                Err(e) => {
                    log_to_file(data_dir, &format!("Failed to run pip install: {}", e));
                }
            }
        }
    } else {
        log_to_file(data_dir, "Dependencies already installed (marker found)");
    }

    Some(venv_python)
}

fn spawn_backend(app: &tauri::AppHandle) {
    // --- 1. Resolve writable data directory ---
    let home_dir = std::env::var("HOME").unwrap_or_default();
    let data_dir = PathBuf::from(&home_dir).join("Library/Application Support/ZenWriter");
    std::fs::create_dir_all(&data_dir).ok();
    
    log_to_file(&data_dir, "=== ZenWriter Backend Startup ===");
    
    // --- 2. Resolve backend working directory ---
    let resource_path = app.path().resource_dir()
        .expect("Failed to get resource dir");
    
    let bundled_backend = resource_path.join("backend");
    let dev_backend = PathBuf::from(DEV_BACKEND_DIR);
    let downloads_backend = PathBuf::from(&home_dir).join("Downloads/writer/backend");
    
    log_to_file(&data_dir, &format!("Checking bundled: {:?} -> exists={}", 
        bundled_backend, bundled_backend.join("main.py").exists()));
    log_to_file(&data_dir, &format!("Checking dev: {:?} -> exists={}", 
        dev_backend, dev_backend.join("main.py").exists()));
    log_to_file(&data_dir, &format!("Checking downloads: {:?} -> exists={}", 
        downloads_backend, downloads_backend.join("main.py").exists()));
    
    let working_dir = if bundled_backend.join("main.py").exists() {
        bundled_backend
    } else if dev_backend.join("main.py").exists() {
        dev_backend
    } else if downloads_backend.join("main.py").exists() {
        downloads_backend
    } else {
        log_to_file(&data_dir, "ERROR: Could not find backend directory!");
        return;
    };
    
    log_to_file(&data_dir, &format!("Using backend from: {:?}", working_dir));
    
    // --- 3. Copy bundled .env to data directory if not already there ---
    let bundled_env = working_dir.join(".env");
    let target_env = data_dir.join(".env");
    if bundled_env.exists() && !target_env.exists() {
        match std::fs::copy(&bundled_env, &target_env) {
            Ok(_) => log_to_file(&data_dir, "Copied .env to data directory"),
            Err(e) => log_to_file(&data_dir, &format!("Failed to copy .env: {}", e)),
        }
    }
    
    // --- 4. Find Python & bootstrap venv ---
    let system_python = find_system_python(&data_dir);
    
    // Also check for existing dev venvs (convenience for development)
    let dev_venv_python = working_dir.join("venv/bin/python");
    let dev_venv_new_python = working_dir.join("venv_new/bin/python");

    let python_cmd: String;

    if dev_venv_python.exists() || dev_venv_new_python.exists() {
        // In dev mode we can use the existing project venv directly
        let p = if dev_venv_python.exists() { dev_venv_python } else { dev_venv_new_python };
        log_to_file(&data_dir, &format!("Using existing dev venv: {:?}", p));
        python_cmd = p.to_string_lossy().to_string();
    } else if let Some(ref sys_py) = system_python {
        // Production: bootstrap an app-local venv
        match ensure_venv(&data_dir, &working_dir, sys_py) {
            Some(venv_py) => {
                python_cmd = venv_py.to_string_lossy().to_string();
            }
            None => {
                log_to_file(&data_dir, "ERROR: Failed to bootstrap venv, falling back to system Python");
                python_cmd = sys_py.clone();
            }
        }
    } else {
        log_to_file(&data_dir, "ERROR: No Python 3 found on this system!");
        return;
    }
    
    log_to_file(&data_dir, &format!("Selected Python: {}", python_cmd));
    
    // --- 5. Spawn backend process ---
    let data_dir_str = data_dir.to_string_lossy().to_string();
    let env_path_str = target_env.to_string_lossy().to_string();
    let log_dir = data_dir.clone();
    
    std::thread::spawn(move || {
        // Kill any existing process on port 8001 (use absolute path for lsof)
        let _ = Command::new("/bin/sh")
            .args(["-c", "/usr/sbin/lsof -ti:8001 | xargs kill -9 2>/dev/null"])
            .output();
        
        std::thread::sleep(std::time::Duration::from_millis(500));
        
        log_to_file(&log_dir, &format!("Spawning: {} -m uvicorn main:app --host 127.0.0.1 --port 8001", python_cmd));
        log_to_file(&log_dir, &format!("Working dir: {:?}", working_dir));
        
        // Open log file for stdout/stderr capture
        let stdout_log = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(log_dir.join("backend_stdout.log"))
            .ok();
        let stderr_log = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(log_dir.join("backend_stderr.log"))
            .ok();
        
        let mut cmd = Command::new(&python_cmd);
        cmd.args(["-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8001"])
            .current_dir(&working_dir)
            .env("ZENWRITER_DATA_DIR", &data_dir_str)
            .env("DOTENV_PATH", &env_path_str);
        
        if let Some(f) = stdout_log {
            cmd.stdout(f);
        }
        if let Some(f) = stderr_log {
            cmd.stderr(f);
        }
        
        match cmd.spawn() {
            Ok(mut child) => {
                log_to_file(&log_dir, &format!("Backend started with PID: {:?}", child.id()));
                match child.wait() {
                    Ok(status) => {
                        log_to_file(&log_dir, &format!("Backend exited with status: {}", status));
                    }
                    Err(e) => {
                        log_to_file(&log_dir, &format!("Backend wait error: {}", e));
                    }
                }
            }
            Err(e) => {
                log_to_file(&log_dir, &format!("FAILED to spawn backend: {}", e));
            }
        }
    });
}
