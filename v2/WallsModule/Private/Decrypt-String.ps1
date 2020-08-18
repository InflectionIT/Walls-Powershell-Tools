function Decrypt($StringToDecrypt) {
    function Decrypt-String($Encrypted, $Passphrase, $salt = "SaltCrypto", $init = "IV_Password") { 
        # If the value in the Encrypted is a string, convert it to Base64 
        if ($Encrypted -is [string]) { 
            $Encrypted = [Convert]::FromBase64String($Encrypted) 
        } 
 
        # Create a COM Object for RijndaelManaged Cryptography 
        $r = new-Object System.Security.Cryptography.RijndaelManaged 
        # Convert the Passphrase to UTF8 Bytes 
        $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase) 
        # Convert the Salt to UTF Bytes 
        $salt = [Text.Encoding]::UTF8.GetBytes($salt) 
 
        # Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits 
        $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8 
        # Create the Intersecting Vector Cryptology Hash with the init 
        $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15] 
 
 
        # Create a new Decryptor 
        $d = $r.CreateDecryptor() 
        # Create a New memory stream with the encrypted value. 
        $ms = new-Object IO.MemoryStream @(, $Encrypted) 
        # Read the new memory stream and read it in the cryptology stream 
        $cs = new-Object Security.Cryptography.CryptoStream $ms, $d, "Read" 
        # Read the new decrypted stream 
        $sr = new-Object IO.StreamReader $cs 
        # Return from the function the stream 
        Write-Output $sr.ReadToEnd() 
        # Stops the stream     
        $sr.Close() 
        # Stops the crypology stream 
        $cs.Close() 
        # Stops the memory stream 
        $ms.Close() 
        # Clears the RijndaelManaged Cryptology IV and Key 
        $r.Clear() 
    } 
    return  Decrypt-String $StringToDecrypt "InflectionIT" 
}