# Catch-all nginx virtualHost for unknown subdomains
# Returns a pretty Catppuccin-themed 404 page
{ pkgs, config, ... }:
let
  inherit (config.lab) domain;

  # Catppuccin Mocha themed 404 page
  notFoundPage = pkgs.writeTextDir "404.html" ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>404 - Not Found</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
          background-color: #1e1e2e;
          color: #cdd6f4;
          min-height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        .container {
          text-align: center;
          padding: 2rem;
        }
        .error-code {
          font-size: 8rem;
          font-weight: 700;
          color: #f38ba8;
          line-height: 1;
          text-shadow: 0 0 40px rgba(243, 139, 168, 0.3);
        }
        .error-title {
          font-size: 1.5rem;
          color: #b4befe;
          margin-top: 1rem;
          font-weight: 500;
        }
        .error-message {
          font-size: 1rem;
          color: #a6adc8;
          margin-top: 1rem;
          max-width: 400px;
        }
        .home-link {
          display: inline-block;
          margin-top: 2rem;
          padding: 0.75rem 1.5rem;
          background-color: #313244;
          color: #cdd6f4;
          text-decoration: none;
          border-radius: 8px;
          transition: background-color 0.2s ease;
        }
        .home-link:hover {
          background-color: #45475a;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="error-code">404</div>
        <div class="error-title">Page Not Found</div>
        <p class="error-message">The service you're looking for doesn't exist on this server.</p>
        <a href="https://${domain}" class="home-link">Go to Dashboard</a>
      </div>
    </body>
    </html>
  '';
in
{
  # Catch-all virtualHost for unknown subdomains
  services.nginx.virtualHosts."_" = {
    default = true;
    forceSSL = true;
    sslCertificate = config.shb.certs.certs.letsencrypt.${domain}.paths.cert;
    sslCertificateKey = config.shb.certs.certs.letsencrypt.${domain}.paths.key;

    root = notFoundPage;

    # Restrict to Tailscale network
    extraConfig = ''
      allow 100.64.0.0/10;
      deny all;
    '';

    locations."/" = {
      extraConfig = ''
        try_files /404.html =404;
      '';
    };
  };
}
