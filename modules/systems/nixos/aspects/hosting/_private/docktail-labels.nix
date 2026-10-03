/**
  Labels that publish an oci-container to the tailnet through docktail.

  The service is reachable as `<host>-<serviceName>` over both HTTP and HTTPS,
  proxied to `containerPort` inside the container. The container must also
  join the `tailscale` network.
*/
{
  hostName,
  serviceName,
  containerPort,
}:
let
  name = "${hostName}-${serviceName}";
  port = toString containerPort;
in
{
  "docktail.service.enable" = "true";
  "docktail.service.network" = "tailscale";
  "docktail.service.name" = name;
  "docktail.service.port" = port;
  "docktail.service.service-port" = "80";
  "docktail.service.service-protocol" = "http";
  "docktail.service.1.enable" = "true";
  "docktail.service.1.name" = name;
  "docktail.service.1.port" = port;
  "docktail.service.1.service-port" = "443";
  "docktail.service.1.service-protocol" = "https";
}
