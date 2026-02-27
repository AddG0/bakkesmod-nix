use std::io::Write;

pub fn log(msg: &str) {
    let mut buf = [0u8; 8]; // "HH:MM:SS"
    let now = unsafe {
        let t = libc::time(std::ptr::null_mut());
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&t, &mut tm);
        tm
    };
    let _ = write!(
        &mut buf[..],
        "{:02}:{:02}:{:02}",
        now.tm_hour, now.tm_min, now.tm_sec
    );
    let time = std::str::from_utf8(&buf[..8]).unwrap_or("??:??:??");
    eprintln!("[{time}] {msg}");
}

#[macro_export]
macro_rules! log {
    ($($arg:tt)*) => {
        $crate::log::log(&format!($($arg)*))
    };
}
