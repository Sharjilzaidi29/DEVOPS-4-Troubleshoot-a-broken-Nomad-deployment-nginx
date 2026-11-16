job "nginx-app" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    network {
      port "http" {
        to = 80
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
        volumes = [
          "local/index.html:/usr/share/nginx/html/index.html",
          "local/default.conf:/etc/nginx/conf.d/default.conf"
        ]
      }

      template {
        data = <<EOH
<!DOCTYPE html>
<html>
<head><title>Nginx on Nomad</title></head>
<body>
  <h1>Nginx Deployment Fixed & Running on Nomad!</h1>
</body>
</html>
EOH
        destination = "local/index.html"
      }

      template {
        data = <<EOH
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /healthz {
        access_log off;
        add_header Content-Type text/plain;
        return 200 "OK\n";
    }
}
EOH
        destination = "local/default.conf"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "nginx-app"
        port = "http"

        check {
          type     = "http"
          path     = "/healthz"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
