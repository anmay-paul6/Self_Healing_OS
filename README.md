# 🛠️ AutoHeal-Linux (Self-Healing System)

AutoHeal-Linux is a Linux-based self-healing system monitoring and recovery tool developed using Bash scripting. It continuously monitors system resources such as CPU usage, memory utilization, disk space, and service status. When abnormal conditions are detected, it automatically performs corrective actions to maintain system stability.

This project demonstrates key operating system concepts including process management, automation, system monitoring, logging, backup, and remote administration.

---

## 🚀 Features

- 📊 Real-time system monitoring (CPU, Memory, Disk)
- ⚙️ Automatic issue detection
- 🔄 Self-healing (process termination, service restart)
- 🧹 Safe disk cleanup
- 🔐 Suspicious login detection & IP blocking
- 📁 Backup before critical operations
- 📝 Logging system for monitoring history
- 🌐 Remote monitoring using SSH
- 🎛️ CLI-based dashboard (menu-driven interface)
- ⏱️ Cron-based automation

---

## 📂 Project Structure

```

Self_Healing_OS/
├── config.sh
├── utils.sh
├── monitor.sh
├── fixer.sh
├── backup.sh
├── dashboard.sh
├── remote_monitor.sh
├── servers.conf
├── cron_setup.sh
├── install.sh
├── logs/
│   └── .gitkeep
├── backups/
│   └── .gitkeep
├── sample_data/
│   └── temp/
│       └── .gitkeep

```

---

## ⚙️ Requirements

- Linux (Ubuntu recommended)
- Bash shell
- Cron service
- SSH (for remote monitoring)
- Basic Linux utilities (`ps`, `df`, `free`, `systemctl`, `awk`, `tar`)

---

## 🛠️ Installation

```

chmod +x install.sh
./install.sh

```

---

## ▶️ Usage

Run dashboard:
```

bash dashboard.sh

```

Run monitoring manually:
```

bash monitor.sh

```

Create backup manually:
```

bash backup.sh

```

Run remote monitoring:
```

bash remote_monitor.sh

```

Setup automatic monitoring (cron):
```

bash cron_setup.sh

```

---

## 👥 Team Members

- Anmay (Team Leader)
- Azijul
- Rajoshree
- Rozy
- Mustafijur

---

## 📌 Notes

- `logs/`, `backups/`, and `sample_data/` folders are created automatically during runtime.
- `.gitkeep` files are used to maintain folder structure in GitHub.
- Root privileges may be required for some operations (service restart, firewall blocking).

---

## 🎯 Use Case

- Linux system monitoring
- Educational operating systems project
- Basic server maintenance
- Learning automation and scripting

---

## 🔮 Future Improvements

- GUI-based dashboard
- AI-based monitoring and decision making
- Email/SMS alert system
- Advanced intrusion detection
- Cloud-based monitoring support

---

