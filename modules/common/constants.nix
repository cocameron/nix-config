# Common constants used across configurations
{
  # User configuration
  primaryUser = "colin";

  # Time zone
  timezone = "America/Los_Angeles";

  # Domain configuration
  domain = {
    nixlab = "nixlab.brucebrus.org";
  };

  # SSH public keys
  sshKeys = {
    colin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWxH6KYmI6UCzu3j+HhnKMhFcDT1oyMilWG76qXF8yV";
  };

  # GPG key
  gpgKey = "08F3DF9DA5BD0D49E1B051FDBFC758DC84917FF4";

  # Git configuration
  git = {
    userName = "Colin Cameron";
    userEmail = "me@ccameron.net";
  };
}
