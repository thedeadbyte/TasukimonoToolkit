
<#PSScriptInfo

.VERSION 1.0

.GUID 1ad8aa40-7435-4884-b9a3-1c45d9b87fbc

.AUTHOR Kalichuza

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 A simple way to encrypt text and text files with AES 

#> 
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Encrypt','Decrypt')]
    [string]$Operation,
    
    [Parameter(Mandatory=$false)]
    [string]$Text,
    
    [Parameter(Mandatory=$false)]
    [string]$Key,
    
    [Parameter(Mandatory=$false)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

function ConvertFrom-SecureString {
    param(
        [System.Security.SecureString]$SecureString
    )
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Encrypt-AES {
    param(
        [string]$PlainText,
        [string]$Key
    )
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key.PadRight(32, '0').Substring(0, 32))
    $ivBytes = New-Object byte[] 16
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($ivBytes)
    $aes = [System.Security.Cryptography.AesManaged]::new()
    $aes.Key = $keyBytes
    $aes.IV = $ivBytes
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
    return [Convert]::ToBase64String($ivBytes + $encryptedBytes)
}

function Decrypt-AES {
    param(
        [string]$CipherText,
        [string]$Key
    )
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key.PadRight(32, '0').Substring(0, 32))
    $cipherBytes = [Convert]::FromBase64String($CipherText)
    $ivBytes = $cipherBytes[0..15]
    $actualCipherBytes = $cipherBytes[16..($cipherBytes.Length - 1)]
    $aes = [System.Security.Cryptography.AesManaged]::new()
    $aes.Key = $keyBytes
    $aes.IV = $ivBytes
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($actualCipherBytes, 0, $actualCipherBytes.Length)
    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

function Process-File {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$Key,
        [bool]$IsEncrypt
    )
    
    try {
        $content = Get-Content -Path $InputFile -Raw
        if ($IsEncrypt) {
            $result = Encrypt-AES -PlainText $content -Key $Key
        } else {
            $result = Decrypt-AES -CipherText $content -Key $Key
        }
        Set-Content -Path $OutputFile -Value $result
        Write-Host "`nOperation completed successfully!"
        Write-Host "Output saved to: $OutputFile"
    }
    catch {
        Write-Host "Error: $_"
    }
}

# If parameters are provided, execute directly
if ($Operation -and $Key) {
    if ($Text) {
        switch ($Operation) {
            "Encrypt" {
                $result = Encrypt-AES -PlainText $Text -Key $Key
                Write-Output $result
            }
            "Decrypt" {
                try {
                    $result = Decrypt-AES -CipherText $Text -Key $Key
                    Write-Output $result
                }
                catch {
                    Write-Error "Error: Invalid cipher text or key"
                }
            }
        }
    }
    elseif ($InputFile -and $OutputFile) {
        Process-File -InputFile $InputFile -OutputFile $OutputFile -Key $Key -IsEncrypt ($Operation -eq "Encrypt")
    }
    exit
}

# Interactive mode
Write-Host "AES Encryption/Decryption Tool"
Write-Host "============================="
Write-Host "Usage: .\AES-Crypto.ps1 -Operation Encrypt|Decrypt -Text 'your text' -Key 'your key'"
Write-Host "Or use interactive mode below:"
Write-Host ""

while ($true) {
    Write-Host "`nChoose an operation:"
    Write-Host "1. Encrypt Text"
    Write-Host "2. Decrypt Text"
    Write-Host "3. Encrypt File"
    Write-Host "4. Decrypt File"
    Write-Host "5. Exit"
    
    $choice = Read-Host "Enter your choice (1-5)"
    
    switch ($choice) {
        "1" {
            $plainText = Read-Host "Enter text to encrypt"
            $secureKey = Read-Host "Enter encryption key" -AsSecureString
            $key = ConvertFrom-SecureString -SecureString $secureKey
            $encrypted = Encrypt-AES -PlainText $plainText -Key $key
            Write-Host "`nEncrypted text: $encrypted"
        }
        "2" {
            $cipherText = Read-Host "Enter text to decrypt"
            $secureKey = Read-Host "Enter decryption key" -AsSecureString
            $key = ConvertFrom-SecureString -SecureString $secureKey
            try {
                $decrypted = Decrypt-AES -CipherText $cipherText -Key $key
                Write-Host "`nDecrypted text: $decrypted"
            }
            catch {
                Write-Host "Error: Invalid cipher text or key"
            }
        }
        "3" {
            $inputFile = Read-Host "Enter path to file to encrypt"
            $outputFile = Read-Host "Enter path for encrypted output file"
            $secureKey = Read-Host "Enter encryption key" -AsSecureString
            $key = ConvertFrom-SecureString -SecureString $secureKey
            Process-File -InputFile $inputFile -OutputFile $outputFile -Key $key -IsEncrypt $true
        }
        "4" {
            $inputFile = Read-Host "Enter path to file to decrypt"
            $outputFile = Read-Host "Enter path for decrypted output file"
            $secureKey = Read-Host "Enter decryption key" -AsSecureString
            $key = ConvertFrom-SecureString -SecureString $secureKey
            Process-File -InputFile $inputFile -OutputFile $outputFile -Key $key -IsEncrypt $false
        }
        "5" {
            Write-Host "Exiting..."
            exit
        }
        default {
            Write-Host "Invalid choice. Please try again."
        }
    }
} 


