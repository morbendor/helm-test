## Overview

Gloo Gateway provides advanced traffic management, security, and observability features for your microservices. This chart is designed to be flexible and production-ready, integrating seamlessly with your existing Kubernetes setup.

This Helm chart deploys the **Gloo Gateway** connector, an Envoy-based API gateway, as part of your Kubernetes infrastructure.

Key Points:
The Security Engine acts as a middleware, processing requests via the extproc integration.
TLS ensures secure communication between Gloo and the Security Engine.
The Helm chart automates the setup, integrating Gloo with the Security Engine by updating the Settings resource.

## Prerequisites

Before deploying this chart, ensure the following components are already configured in your environment:

- **GatewayParameters**: Define the core gateway configuration.
- **HttpListenerOptions**: Set HTTP listener behaviors and options.
- **Settings**: Global Gloo settings for your deployment.
- **GatewayClass**: Specify the gateway class for your environment.
- **ListenerOption**: (Required for classic load balancer with proxy protocol) Enable proxy protocol support if needed.

## Helm Chart deployed componenets

- **Upstream**:  Represents an external service that Gloo can route traffic to (In eWaf case, the Security Engine Service).

## Installation
 
### Add the Helm Repository

To install in a production environment, first add the Helm repository:

```sh
helm repo add imperva-anywhere https://imperva.jfrog.io/artifactory/imperva-anywhere --username "$username" --password "$password"
```

### Install the Chart

You can install the chart in two ways:

#### Production Installation

Use the following command to install from the remote repository:

```sh
helm install imperva imperva-anywhere/imperva-stack --version <version> -f values.yaml -n <release-namespace> --create-namespace --debug
```

Replace `<version>` and `<release-namespace>` with your desired values.

#### Local Development Installation

For local changes, use the `devkit` tool and install from your local directory:

```sh
./devkit enable <submodule_name> <mybranch>
helm install imperva . -f values.yaml -n <release-namespace> --create-namespace --debug
```

Replace `<mybranch>` and `<release-namespace>` as needed.
## Traffic Flow

The typical traffic flow in this deployment is as follows:

1. **Network Load Balancer (NLB)** receives incoming traffic and forwards it to the Gloo Gateway pod running in the release namespace.
2. **Gloo Gateway** processes the request using its configured Gateway and HttpRoute resources, routing traffic to the appropriate application.
3. **Upstream Configuration**: For requests requiring external processing, Gloo routes traffic (using TLS) to the Security Engine service, which acts as an external processor.
4. **External Processor Integration**: The connection to the Security Engine is defined in the Gloo `Settings` resource under the `extproc` attribute which specifies the Upstream. This configuration is added during Helm chart installation, enabling the integration between Gloo and the Security Engine.

Client
  |
  v
NLB
  |
  v
K8s Service (release namespace)
  |
  v
Gloo Pod (Gateway)
  |
  v
HTTPRoute
  |
  v
Upstream (TLS)
  |
  v
Security Engine (External Processor)
  |
  v
Application

Key Points:
The Security Engine acts as a middleware, processing requests via the extproc integration.
TLS ensures secure communication between Gloo and the Security Engine.
The Helm chart automates the setup, integrating Gloo with the Security Engine by updating the Settings resource.