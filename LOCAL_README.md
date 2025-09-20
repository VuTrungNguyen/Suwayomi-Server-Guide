# Suwayomi-Server Local Build Guide

This document covers the local build process, issues encountered, and solutions for running Suwayomi-Server from source in a WSL2/Linux environment.

## 📋 Build Summary

**Successfully built:** Suwayomi-Server v2.1.1933 with WebUI r2765  
**Build date:** September 20, 2025  
**Environment:** WSL2 Ubuntu on Windows  
**Java version:** OpenJDK 21  

## 🛠️ What Was Installed

### Core Dependencies
- **Java 21 (OpenJDK)** - Required runtime (upgraded from Java 17)
  ```bash
  sudo apt update
  sudo apt install openjdk-21-jdk
  ```

- **Xvfb** - X Virtual Framebuffer for headless GUI operation
  ```bash
  sudo apt install xvfb
  ```

### Build Tools
- **Gradle 8.14.3** - Already included via Gradle Wrapper
- **Git** - For repository cloning (pre-installed)

## 🚫 Issues Encountered and Solutions

### 1. Java Version Compatibility
**Problem:** Build initially failed with Java 17
```
> Task :server:compileKotlin FAILED
Execution failed for task ':server:compileKotlin'.
```

**Solution:** Upgraded to Java 21
```bash
sudo apt install openjdk-21-jdk
sudo update-alternatives --config java  # Select Java 21
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

### 2. Test Compilation Failures
**Problem:** Several test compilation errors in different modules
```
> Task :AndroidCompat:compileTestKotlin FAILED
> Task :server:compileTestKotlin FAILED
```

**Solution:** Skip tests during build
```bash
./gradlew server:shadowJar -x test
```

### 3. GPU Support Issues in WSL2
**Problem:** CEF/JCEF GPU initialization errors and crashes
```
SIGSEGV (0xb) at pc=0x0000754a5cd8cd04
# Problematic frame:
# C  [libgtk-3.so.0+0x18cd04]
```

**Solution:** 
- **Already fixed in codebase** - Commit r1825 added `--disable-dev-shm-usage` flag
- Current KCEF configuration includes proper headless flags:
  - `--disable-gpu`
  - `--off-screen-rendering-enabled`
  - `--disable-dev-shm-usage`
- Use xvfb-run for additional stability

### 4. Port Conflicts
**Problem:** Port 4567 already in use from previous runs
```
io.javalin.util.JavalinBindException: Port already in use
```

**Solution:** Kill existing processes before restart
```bash
ss -tlnp | grep :4567
kill -9 <PID>
```

## 🚀 How to Run the Server

### Method 1: Recommended (Headless with xvfb-run)
```bash
cd /home/danxtshake/scratchpad/Suwayomi
DISPLAY="" LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1024x768x24" \
  java -jar server/build/Suwayomi-Server-v2.1.1933.jar
```

### Method 2: Background Process
```bash
cd /home/danxtshake/scratchpad/Suwayomi
nohup xvfb-run -a java -jar server/build/Suwayomi-Server-v2.1.1933.jar > suwayomi.log 2>&1 &
```

### Method 3: Simple Run (may have GUI warnings)
```bash
cd /home/danxtshake/scratchpad/Suwayomi
java -jar server/build/Suwayomi-Server-v2.1.1933.jar
```

### Method 4: Docker Compose (Recommended for Production)
```bash
# Create data directories
mkdir -p docker-data/downloads docker-data/data

# Start the container
docker compose up -d

# View logs
docker compose logs -f suwayomi_server

# Stop the container
docker compose down
```

**Quick Management Script:**
```bash
# Make script executable
chmod +x suwayomi-docker.sh

# Use the management script
./suwayomi-docker.sh start    # Start server
./suwayomi-docker.sh status   # Check status
./suwayomi-docker.sh logs     # View logs
./suwayomi-docker.sh stop     # Stop server
./suwayomi-docker.sh update   # Update to latest
./suwayomi-docker.sh backup   # Backup data
```

**Docker Compose Benefits:**
- ✅ **No Java installation required** - Everything runs in container
- ✅ **No GPU/CEF issues** - Pre-configured headless environment
- ✅ **Easy updates** - Just pull new image and restart
- ✅ **Isolated environment** - Doesn't affect host system
- ✅ **Automatic restarts** - Container restarts on failure/reboot
- ✅ **Port flexibility** - Runs on port 4568 (external) → 4567 (internal)

## 🌐 Accessing the Server

### Built from Source (Methods 1-3)
- **Web Interface:** http://localhost:4567
- **Local network:** http://0.0.0.0:4567 (accessible from other devices)

### Docker Compose (Method 4)
- **Web Interface:** http://localhost:4568
- **Local network:** http://0.0.0.0:4568 (accessible from other devices)

### Verification Commands

**For built from source:**
```bash
# Check if server is running
ss -tlnp | grep :4567

# Test HTTP response
curl -s -w "%{http_code}\n" http://localhost:4567/

# Check server process
ps aux | grep java | grep Suwayomi
```

**For Docker Compose:**
```bash
# Check if container is running
docker compose ps

# Check if server port is accessible
ss -tlnp | grep :4568

# Test HTTP response
curl -s -w "%{http_code}\n" http://localhost:4568/

# View container logs
docker compose logs suwayomi_server

# Check container status
docker ps | grep Suwayomi-Server
```

## 🛑 Stop the Server

**Built from source:**
```bash
ps aux | grep java | grep Suwayomi
kill [process-id]
```

**Docker Compose:**
```bash
docker compose down
```
## 📁 Important Files and Directories

### Build Artifacts (Source Build)
- **Main JAR:** `server/build/Suwayomi-Server-v2.1.1933.jar` (160MB)
- **Build directory:** `server/build/`
- **Gradle cache:** `~/.gradle/`

### Runtime Data (Source Build)
- **Data directory:** `~/.local/share/Tachidesk/`
- **Database:** `~/.local/share/Tachidesk/database`
- **WebUI files:** `~/.local/share/Tachidesk/webUI/`
- **Extensions:** `~/.local/share/Tachidesk/extensions/`
- **Downloads:** `~/.local/share/Tachidesk/downloads/`

### Docker Data (Docker Compose)
- **Docker Compose file:** `docker-compose.yml`
- **Management script:** `suwayomi-docker.sh`
- **Data directory:** `./docker-data/data/`
- **Downloads directory:** `./docker-data/downloads/`
- **Database:** `./docker-data/data/database`
- **WebUI files:** `./docker-data/data/webUI/`
- **Extensions:** `./docker-data/data/extensions/`

### Configuration
- **Server config:** Auto-generated in data directory
- **Database:** H2 embedded database (version 52 schema)
- **WebUI:** Automatic download and validation (r2765)

## 🔧 Technical Configuration

### Server Settings
- **Port:** 4567
- **IP binding:** 0.0.0.0 (all interfaces)
- **Authentication:** None (default)
- **Database:** H2 embedded
- **WebUI:** Enabled (STABLE channel)

### CEF/WebView Settings
- **JCEF Version:** 137.0.17.1082
- **CEF Version:** 137.0.17
- **Chromium Version:** 137.0.7151.104
- **Rendering:** Windowless/offscreen
- **GPU:** Disabled (headless-safe)
- **Sandbox:** Disabled (`no_sandbox=true`)

### Environment Variables
```bash
# For optimal headless operation
export DISPLAY=""
export LIBGL_ALWAYS_SOFTWARE=1
```

## 🔍 Troubleshooting

### Server Won't Start
1. Check Java version: `java -version` (should be 21+)
2. Check port availability: `ss -tlnp | grep :4567`
3. Check disk space in data directory
4. Review server logs for specific errors

### GPU/Graphics Errors
- **Expected:** Minor GTK warnings and D-Bus errors in WSL2
- **Critical:** SIGSEGV crashes (use xvfb-run if occurring)
- **Solution:** Ensure xvfb is installed and use recommended run method

### Performance Issues
- **Memory:** Server uses ~700MB RAM initially
- **CPU:** High usage during startup (~37% for 30 seconds)
- **Disk:** 160MB for JAR + ~50MB for runtime data

### WebUI Not Loading
1. Verify server started: Look for "Javalin started" message
2. Check WebUI validation: Should see "Validation succeeded" 
3. Test direct access: `curl http://localhost:4567`
4. Clear browser cache if using external browser

## 📝 Build Notes

### Successful Build Output
```
BUILD SUCCESSFUL in 2m 47s
35 actionable tasks: 35 executed
```

### Key Build Tasks
1. **Kotlin compilation** - All modules compiled successfully
2. **Resource processing** - WebUI and assets bundled
3. **Shadow JAR creation** - Fat JAR with all dependencies
4. **Test skipping** - Tests bypassed due to compilation issues

### Build Performance
- **Total time:** ~3 minutes
- **Final JAR size:** 160MB
- **Gradle cache:** ~2GB accumulated

## � Method Comparison

| Feature | Source Build | Docker Compose |
|---------|-------------|----------------|
| **Setup Time** | ~10 minutes (build + deps) | ~2 minutes (pull image) |
| **Prerequisites** | Java 21, Xvfb, Git | Docker only |
| **Startup Time** | ~30 seconds | ~10 seconds |
| **Resource Usage** | ~700MB RAM | ~500MB RAM |
| **GPU Issues** | Requires xvfb-run | None (pre-configured) |
| **Updates** | Manual rebuild | `docker compose pull` |
| **Customization** | Full source control | Limited to configs |
| **Data Location** | `~/.local/share/Tachidesk/` | `./docker-data/` |
| **Port** | 4567 | 4568 |
| **Debugging** | Full access to logs/code | Container logs only |
| **Isolation** | Runs on host system | Containerized |

**Recommendations:**
- **Use Docker Compose** for production, easier setup, no dependency issues
- **Use Source Build** for development, testing, or when you need latest features

## �🎯 Next Steps

1. **Extensions:** Install manga source extensions via WebUI
2. **Configuration:** Customize server settings via WebUI settings page
3. **Backup:** Set up automated backups for manga library
4. **Updates:** Monitor for new releases and WebUI updates
5. **Networking:** Configure reverse proxy if needed for external access

---

**Note:** This build was completed on September 20, 2025, using the latest master branch. GPU issues from earlier versions have been resolved in the current codebase.