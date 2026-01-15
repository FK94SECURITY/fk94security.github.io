# Factory Reset - macOS

## Cuándo Hacer Factory Reset

- Sospecha de compromiso/malware
- Venta o transferencia del equipo
- Performance extremadamente degradado
- Empezar desde cero con setup seguro

---

## Antes de Empezar

### 1. Backup de Datos Importantes

```bash
# Verificar Time Machine
tmutil listbackups

# O copiar manualmente a disco externo:
# - ~/Documents
# - ~/Desktop
# - ~/Downloads
# - Fotos de Photos.app (exportar)
# - Notas (exportar)
# - Keychain (exportar passwords a 1Password primero)
```

### 2. Desautorizar Servicios

- [ ] **iTunes/Music:** Account > Authorizations > Deauthorize This Computer
- [ ] **iCloud:** System Settings > Apple ID > Sign Out
- [ ] **iMessage:** Messages > Settings > iMessage > Sign Out
- [ ] **Find My:** Desactivar en System Settings > Apple ID > Find My

### 3. Guardar Información Necesaria

- [ ] Licencias de software
- [ ] Passwords (exportar de Keychain a password manager)
- [ ] Serial number del Mac (About This Mac)
- [ ] Lista de apps instaladas

```bash
# Listar apps instaladas
ls /Applications > ~/Desktop/apps_installed.txt
```

---

## Proceso de Factory Reset

### Opción A: macOS Ventura o posterior (Erase All Content)

1. **System Settings > General > Transfer or Reset > Erase All Content and Settings**
2. Autenticar con password de admin
3. Confirmar que querés borrar todo
4. El Mac se reiniciará y borrará todo

### Opción B: Recovery Mode (Cualquier versión de macOS)

#### Paso 1: Entrar a Recovery Mode

**Intel Mac:**
1. Apagar el Mac
2. Encender y mantener **Cmd + R** hasta ver el logo de Apple

**Apple Silicon (M1/M2/M3):**
1. Apagar el Mac
2. Mantener presionado el botón de encendido hasta ver "Loading startup options"
3. Seleccionar "Options" > Continue

#### Paso 2: Borrar el Disco

1. En Recovery, abrir **Disk Utility**
2. Ver > Show All Devices
3. Seleccionar el disco principal (generalmente "Macintosh HD" o el SSD interno)
4. Click en **Erase**
5. Configurar:
   - Name: Macintosh HD
   - Format: **APFS** (para SSD) o Mac OS Extended (Journaled) para HDD
   - Scheme: GUID Partition Map
6. Click en Erase
7. Esperar que termine
8. Cerrar Disk Utility

#### Paso 3: Reinstalar macOS

1. Seleccionar **Reinstall macOS**
2. Seguir las instrucciones
3. Seleccionar el disco que acabás de formatear
4. Esperar (puede tomar 30-60 minutos)

---

## Secure Erase (Para Venta/Transferencia)

Si vas a vender o regalar el Mac, el borrado estándar de APFS es suficiente para SSDs modernos (los datos se encriptan con FileVault y la key se destruye).

Para HDDs o paranoia extra:

```bash
# En Terminal de Recovery Mode
# CUIDADO: Esto borra TODO permanentemente

# Listar discos
diskutil list

# Secure erase (solo HDD, no SSD)
diskutil secureErase 2 /dev/diskX
```

---

## Post-Reset: Setup Seguro

Después del factory reset, seguir estos pasos:

### 1. Durante Setup Inicial

- [ ] Crear cuenta con nombre genérico si preocupa privacidad
- [ ] NO conectar a WiFi hasta terminar (opcional, para setup offline)
- [ ] Configurar contraseña fuerte
- [ ] Skip "Sign in with Apple ID" si querés setup limpio primero

### 2. Primeras Configuraciones

```bash
# Después de setup inicial, ejecutar nuestro script de hardening
sudo ./harden-macos.sh --audit  # Ver estado
sudo ./harden-macos.sh          # Aplicar hardening
```

### 3. Instalar Software Esencial

1. **Password Manager** (1Password o Bitwarden)
2. **Browser** (Firefox o Brave)
3. Resto de apps desde App Store o sitios oficiales

### 4. Restaurar Datos

- Copiar archivos desde backup
- NO restaurar Time Machine completo (trae configuraciones viejas)
- Restaurar selectivamente

---

## Troubleshooting

### No puedo entrar a Recovery Mode

**Intel Mac:**
- Intentar Cmd + Option + R (Internet Recovery)
- Verificar que el teclado funciona

**Apple Silicon:**
- Asegurar que el Mac está completamente apagado
- Mantener el botón por 10+ segundos

### Disk Utility no muestra el disco

- View > Show All Devices
- Si no aparece, puede haber problema de hardware

### Error al reinstalar macOS

- Verificar conexión a internet
- Probar Internet Recovery (Cmd + Option + R)
- Verificar fecha/hora del sistema (en Terminal: `date`)

---

## Checklist Final

- [ ] Datos respaldados
- [ ] Servicios desautorizados
- [ ] Disco borrado
- [ ] macOS reinstalado
- [ ] Cuenta nueva creada
- [ ] Hardening aplicado
- [ ] Apps esenciales instaladas

---

*FK94 Security - https://github.com/fk94security/fk94_security*
