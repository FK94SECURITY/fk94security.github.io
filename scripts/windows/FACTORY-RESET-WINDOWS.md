# Factory Reset - Windows 10/11

## Cuándo Hacer Factory Reset

- Sospecha de compromiso/malware
- Venta o transferencia del equipo
- Performance extremadamente degradado
- Empezar desde cero con setup seguro

---

## Antes de Empezar

### 1. Backup de Datos Importantes

```powershell
# Carpetas importantes a respaldar:
# C:\Users\TuUsuario\Documents
# C:\Users\TuUsuario\Desktop
# C:\Users\TuUsuario\Pictures
# C:\Users\TuUsuario\Downloads

# Listar programas instalados
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, Publisher |
    Export-Csv "$env:USERPROFILE\Desktop\installed_programs.csv"
```

### 2. Desautorizar/Cerrar Sesión de Servicios

- [ ] **Microsoft Account:** Settings > Accounts > Your info
- [ ] **OneDrive:** Cerrar sesión y desincronizar
- [ ] **Office 365:** Account > Sign Out
- [ ] **Steam, Epic, etc.:** Cerrar sesión
- [ ] **Browsers:** Cerrar sesión de cuentas sincronizadas

### 3. Guardar Información Necesaria

- [ ] Licencias de software (keys de producto)
- [ ] Product key de Windows (si es retail)
- [ ] Passwords (exportar a password manager)
- [ ] Drivers especiales (de manufacturer)

```powershell
# Ver product key de Windows (si está en BIOS)
wmic path softwarelicensingservice get OA3xOriginalProductKey

# Exportar drivers instalados
dism /online /export-driver /destination:"$env:USERPROFILE\Desktop\drivers_backup"
```

---

## Proceso de Factory Reset

### Opción A: Reset desde Windows (Recomendado)

#### Windows 11:

1. **Settings > System > Recovery**
2. Click en **Reset PC**
3. Elegir opción:
   - **Keep my files:** Solo reinstala Windows (NO recomendado si hay malware)
   - **Remove everything:** Borrado completo (RECOMENDADO)
4. Elegir reinstalación:
   - **Cloud download:** Descarga Windows fresco de Microsoft
   - **Local reinstall:** Usa archivos locales
5. Configurar opciones adicionales:
   - **Clean data:** Sí (más seguro pero más lento)
6. Confirmar y esperar

#### Windows 10:

1. **Settings > Update & Security > Recovery**
2. En "Reset this PC" click en **Get started**
3. Mismas opciones que Windows 11

### Opción B: Fresh Install desde USB (Más Limpio)

#### Paso 1: Crear USB de Instalación

1. Descargar Media Creation Tool de microsoft.com
2. Ejecutar y crear USB booteable (mínimo 8GB)
3. O usar Rufus con ISO de Windows

#### Paso 2: Boot desde USB

1. Reiniciar PC
2. Entrar al Boot Menu:
   - **Dell:** F12
   - **HP:** F9 o Esc
   - **Lenovo:** F12
   - **ASUS:** F8 o Esc
   - **Acer:** F12
3. Seleccionar USB

#### Paso 3: Instalación Limpia

1. Seleccionar idioma y región
2. Click en **Install now**
3. Ingresar product key o "I don't have a product key"
4. Seleccionar edición de Windows
5. **Custom: Install Windows only (advanced)**
6. **IMPORTANTE:** Borrar TODAS las particiones
   - Seleccionar cada partición > Delete
   - Quedará "Unallocated space"
7. Seleccionar el espacio sin asignar
8. Click en Next
9. Esperar instalación

---

## Secure Erase (Para Venta/Transferencia)

### Opción 1: Durante Reset

En las opciones de Reset, seleccionar:
- "Remove everything"
- "Clean the drive" > "Fully clean the drive"

### Opción 2: Usando Diskpart (Más Seguro)

```cmd
# En CMD como Administrator (desde USB de instalación)
diskpart
list disk
select disk 0
clean all  # CUIDADO: Borra todo el disco
exit
```

### Opción 3: DBAN (Para Máxima Seguridad)

1. Descargar DBAN ISO
2. Crear USB booteable
3. Boot y ejecutar "autonuke"
4. Reinstalar Windows después

---

## Post-Reset: Setup Seguro

### 1. Durante Setup Inicial (OOBE)

- [ ] Conectar a internet (necesario para activación)
- [ ] **Usar cuenta local** en vez de Microsoft Account:
  - "Sign-in options" > "Offline account" > "Limited experience"
  - O desconectar internet durante setup
- [ ] Crear password fuerte
- [ ] Deshabilitar todas las opciones de telemetría/privacidad
- [ ] No usar Cortana

### 2. Primeras Configuraciones

```powershell
# Ejecutar nuestro script de hardening
# Abrir PowerShell como Administrator
Set-ExecutionPolicy Bypass -Scope Process
.\harden-windows.ps1 -Audit  # Ver estado
.\harden-windows.ps1         # Aplicar hardening
```

### 3. Windows Update

```powershell
# Instalar todas las actualizaciones
Settings > Windows Update > Check for updates
# Reiniciar varias veces hasta que no haya más updates
```

### 4. Instalar Software Esencial

1. **Password Manager** (1Password o Bitwarden)
2. **Browser** (Firefox o Brave) - NO usar Edge para descargas
3. **Antivirus:** Windows Defender es suficiente
4. Resto de apps desde sitios oficiales

### 5. Desinstalar Bloatware

```powershell
# Desinstalar apps preinstaladas innecesarias
Get-AppxPackage *xbox* | Remove-AppxPackage
Get-AppxPackage *zune* | Remove-AppxPackage
Get-AppxPackage *bing* | Remove-AppxPackage
Get-AppxPackage *candy* | Remove-AppxPackage
Get-AppxPackage *solitaire* | Remove-AppxPackage
```

---

## Troubleshooting

### No puedo entrar al Boot Menu

- Deshabilitar Fast Boot en BIOS
- Mantener presionada la tecla desde antes de que encienda

### Windows no reconoce el USB

- Probar otro puerto USB (usar USB 2.0 si es posible)
- Recrear el USB con Rufus

### Error de activación después de reset

- Windows debería activarse automáticamente si estaba activado antes
- Usar "Troubleshoot" en Settings > Activation
- Vincular licencia a Microsoft Account antes del reset

### BitLocker solicita recovery key

- Buscar en account.microsoft.com/devices
- Si no la tenés, el disco está perdido (backup importante!)

### Drivers faltantes después de instalación

- Windows Update debería instalar la mayoría
- Ir al sitio del manufacturer para drivers específicos
- Especialmente importante: chipset, red, gráficos

---

## Checklist Final

- [ ] Datos respaldados
- [ ] Product keys guardados
- [ ] Servicios desautorizados
- [ ] Disco borrado completamente
- [ ] Windows instalado limpio
- [ ] Cuenta local creada
- [ ] Telemetría deshabilitada
- [ ] Windows Update completado
- [ ] Hardening script ejecutado
- [ ] Password manager instalado
- [ ] Bloatware removido
- [ ] BitLocker habilitado

---

*FK94 Security - https://github.com/fk94security/fk94_security*
