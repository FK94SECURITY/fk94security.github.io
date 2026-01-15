# Factory Reset - Linux

## Cuándo Hacer Factory Reset

- Sospecha de compromiso/malware
- Venta o transferencia del equipo
- Performance extremadamente degradado
- Cambio de distribución
- Empezar desde cero con setup seguro

---

## Antes de Empezar

### 1. Backup de Datos Importantes

```bash
# Carpetas importantes:
# /home/usuario/
# /etc/ (configuraciones del sistema)

# Listar paquetes instalados
# Debian/Ubuntu
dpkg --get-selections > ~/installed_packages.txt

# Fedora/RHEL
rpm -qa > ~/installed_packages.txt

# Arch
pacman -Qqe > ~/installed_packages.txt

# Backup del home directory
tar -czvf ~/home_backup_$(date +%Y%m%d).tar.gz /home/usuario/
```

### 2. Guardar Configuraciones Importantes

```bash
# SSH keys
cp -r ~/.ssh ~/backup_ssh/

# GPG keys
gpg --export-secret-keys > ~/backup_gpg_private.asc
gpg --export > ~/backup_gpg_public.asc

# Dotfiles
cp ~/.bashrc ~/.zshrc ~/.vimrc ~/backup_dotfiles/ 2>/dev/null
```

### 3. Información del Sistema

```bash
# Guardar info del hardware
lspci > ~/hardware_info.txt
lsusb >> ~/hardware_info.txt
cat /proc/cpuinfo >> ~/hardware_info.txt

# Particiones actuales
lsblk > ~/partitions_info.txt
cat /etc/fstab >> ~/partitions_info.txt
```

---

## Proceso de Reinstalación

### Paso 1: Crear USB de Instalación

**Desde Linux:**
```bash
# Descargar ISO de la distro elegida
# Identificar el USB
lsblk

# Escribir ISO (CUIDADO: verificar /dev/sdX correcto)
sudo dd if=distro.iso of=/dev/sdX bs=4M status=progress && sync

# O usar herramientas gráficas:
# - balenaEtcher
# - Ventoy (múltiples ISOs)
```

**Desde Windows:**
- Usar Rufus o balenaEtcher

### Paso 2: Boot desde USB

1. Reiniciar
2. Entrar al Boot Menu (F12, F2, Esc, Delete según BIOS)
3. Seleccionar USB
4. Elegir "Try/Install" o directo "Install"

### Paso 3: Instalación

#### Durante la instalación:

1. **Seleccionar idioma y teclado**

2. **Tipo de instalación:**
   - "Erase disk and install" - RECOMENDADO para reset limpio
   - "Something else" - Para particionado manual

3. **Si elegís particionado manual:**
   ```
   Partición recomendada (GPT + UEFI):
   - /boot/efi: 512MB, FAT32
   - /: resto del disco, ext4 (o btrfs)
   - swap: igual a RAM si <16GB, 16GB si >16GB RAM
   ```

4. **Crear usuario:**
   - Username sin datos personales
   - Password fuerte
   - Habilitar "Require password to log in"

5. **Opciones adicionales:**
   - Habilitar "Encrypt the new installation" (LUKS)
   - Deshabilitar "Download updates while installing" para control

---

## Secure Erase (Para Venta/Transferencia)

### Opción 1: Durante Instalación

Seleccionar "Erase disk" con opción de encriptación borra todo de forma segura.

### Opción 2: Desde Live USB

```bash
# Identificar disco
lsblk

# CUIDADO: Esto borra TODO en /dev/sdX
# Para SSD (TRIM):
sudo blkdiscard /dev/sdX

# Para HDD (más lento, más seguro):
sudo dd if=/dev/urandom of=/dev/sdX bs=4M status=progress

# Alternativa con shred:
sudo shred -vfz -n 3 /dev/sdX
```

### Opción 3: DBAN

Para paranoia máxima, usar Darik's Boot and Nuke:
1. Descargar DBAN ISO
2. Boot desde USB
3. Ejecutar "autonuke"
4. Reinstalar después

---

## Post-Instalación: Setup Seguro

### 1. Actualizar Sistema

```bash
# Debian/Ubuntu
sudo apt update && sudo apt upgrade -y

# Fedora
sudo dnf upgrade -y

# Arch
sudo pacman -Syu
```

### 2. Ejecutar Script de Hardening

```bash
# Descargar o copiar nuestro script
chmod +x harden-linux.sh
sudo ./harden-linux.sh --audit  # Ver estado
sudo ./harden-linux.sh          # Aplicar hardening
```

### 3. Instalar Software Esencial

```bash
# Firewall (si no vino instalado)
sudo apt install ufw
sudo ufw enable

# Password manager CLI
sudo apt install pass

# O instalar 1Password/Bitwarden desde sus repos oficiales
```

### 4. Configurar Encriptación del Home (si no encriptaste disco completo)

```bash
# Instalar ecryptfs
sudo apt install ecryptfs-utils

# Migrar home a encriptado
sudo ecryptfs-migrate-home -u usuario
```

### 5. Configurar Actualizaciones Automáticas

**Ubuntu:**
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

**Fedora:**
```bash
sudo dnf install dnf-automatic
sudo systemctl enable --now dnf-automatic.timer
```

---

## Distribuciones Recomendadas para Seguridad

| Distro | Nivel | Uso |
|--------|-------|-----|
| **Ubuntu LTS** | Básico | Desktop general, buena compatibilidad |
| **Fedora** | Intermedio | Más actualizado, SELinux por defecto |
| **Debian** | Intermedio | Muy estable, servidores |
| **Qubes OS** | Avanzado | Máxima seguridad, compartimentalización |
| **Tails** | Especial | Anonimato, live USB, no deja rastros |
| **Whonix** | Especial | Todo tráfico por Tor |

---

## Troubleshooting

### No bootea después de instalación

```bash
# Desde Live USB
sudo mount /dev/sdXY /mnt  # Partición root
sudo mount /dev/sdXZ /mnt/boot/efi  # Partición EFI
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo chroot /mnt
grub-install --target=x86_64-efi
update-grub
exit
sudo reboot
```

### WiFi no funciona

```bash
# Ver hardware de red
lspci | grep -i network
lsusb | grep -i wireless

# Instalar drivers comunes
sudo apt install linux-firmware
sudo apt install firmware-iwlwifi  # Intel
```

### Dual boot con Windows no aparece

```bash
sudo os-prober
sudo update-grub
```

### Olvidé la passphrase de LUKS

- No hay recuperación posible
- Los datos están perdidos
- Por eso es crucial guardar la passphrase de forma segura

---

## Checklist Final

- [ ] Datos respaldados (home, SSH keys, GPG)
- [ ] Info de paquetes guardada
- [ ] Disco borrado completamente
- [ ] Distribución instalada
- [ ] Encriptación habilitada (LUKS)
- [ ] Usuario creado con password fuerte
- [ ] Sistema actualizado
- [ ] Firewall habilitado
- [ ] Script de hardening ejecutado
- [ ] Actualizaciones automáticas configuradas
- [ ] Software esencial instalado

---

*FK94 Security - https://github.com/fk94security/fk94_security*
