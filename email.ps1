# Configuration Variables
$smtpServer = "smtp.office365.com"  # SMTP Server address
$smtpUsername = "services@hhcfutures.com"  # SMTP sender email address
$smtpPassword = "1972Mercurymarquis)"  # SMTP password
$recipient = "signals@hhcfutures.com"  # Email recipient
$subject = "ALERT! MultiCharts64 Process was RESTARTED"  # Email subject
$body = "The MultiCharts64 Program has been RESTARTED because it got stuck for 5 minutes via The Monitoring Script - Confirm everything looks good!"  # Email body

try {
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, 587)  # Adjust port as per your SMTP server configuration
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)

    $mail = New-Object Net.Mail.MailMessage
    $mail.From = $smtpUsername
    $mail.To.Add($recipient)
    $mail.Subject = $subject
    $mail.Body = $body

    $smtp.Send($mail)
    Write-Host "Alert email sent successfully."
}
catch {
    Write-Host "Failed to send email. $_.Exception.Message"
}

