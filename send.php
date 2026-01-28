<?php
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  exit;
}

$first = trim($_POST['first_name'] ?? '');
$last = trim($_POST['last_name'] ?? '');
$email = filter_var($_POST['email'] ?? '', FILTER_VALIDATE_EMAIL);
$subject = trim($_POST['subject'] ?? '');
$message = trim($_POST['message'] ?? '');

if (!$first || !$last || !$email || !$subject || !$message) {
  http_response_code(400);
  echo 'Données invalides';
  exit;
}

$to = 'contact@studio-utopia.com';
$headers = "From: $first $last <$email>\r\nReply-To: $email";
$body = "Nom: $first $last\nEmail: $email\n\n$message";

mail($to, $subject, $body, $headers);
echo 'OK';
?>