# Multicloud Private Connectivity Lab

Laboratorio incremental para estudiar conectividad privada entre AWS y Google
Cloud, con Azure previsto para una fase posterior. El objetivo es comprender y
verificar routing, VPN IPsec, BGP y observabilidad, no solo desplegar una
arquitectura funcional.

## Roadmap del laboratorio

Avanzaremos en iteraciones pequenas. Cada fase incluira decisiones razonadas,
pruebas verificables y actualizacion de la documentacion, los diagramas y el
diario. Antes de crear recursos facturables revisaremos su coste y como
eliminarlos.

**Estado actual: Fases 0 a 5 completadas.** Las fases posteriores son una hoja
de ruta, no una autorizacion para desplegarlas.

| Fase | Trabajo y objetivo | Estado |
| --- | --- | --- |
| 0 — Preparacion de cuentas | Preparar cuentas AWS y GCP, credenciales, aislamiento, presupuestos y providers Terraform; verificar identidades y un plan sin cambios. | Completada |
| 1 — Redes del laboratorio | Definir el modelo de subredes y crear una VPC propia en AWS y una VPC propia en GCP; verificar direccionamiento y aislamiento. | Completada |
| 2 — VMs y routing local | Crear una VM minima en cada cloud y estudiar las rutas locales y los controles de acceso. | Completada |
| 3 — VPN Site-to-Site | Elegir y configurar una VPN IPsec AWS ↔ GCP con un enfoque pedagogico; entender gateways, tuneles y rutas. | Completada |
| 4 — Conectividad privada | Probar comunicacion entre las IPs privadas de las VMs y verificar las rutas y reglas que la permiten. | Completada |
| 5 — Acceso privado a servicios | Acceder a S3 desde ambas clouds, federar la identidad de GCP en AWS y preparar AWS CLI desde Cloud Storage sin IP publica. | Completada |
| 6 — Observabilidad | Incorporar Flow Logs, logs y metricas para correlacionar conexiones y obtener evidencia del recorrido del trafico. | Pendiente |
| 7 — Trafico privado e Internet | Comparar conexiones hacia la otra cloud y hacia Internet, demostrando la ruta utilizada en cada caso. | Pendiente |
| 8 — BGP avanzado y crecimiento | Ampliar a cuatro tuneles, estudiar seleccion y failover de rutas y profundizar en anuncios BGP. | Pendiente |
| 9 — Diagnostico de fallos | Provocar fallos controlados de routing y VPN, diagnosticarlos mediante logs y metricas y recuperar la conectividad. | Pendiente |
| 10 — Azure | Preparar Azure e incorporar una VNet con CIDR `10.20.0.0/16` a la conectividad privada. | Pendiente |
| 11 — Arquitecturas avanzadas | Estudiar hub-and-spoke y transit routing con AWS Transit Gateway, Azure Virtual WAN y GCP Network Connectivity Center; revisar costes antes de cualquier despliegue. | Pendiente |
| 12 — Conectividad dedicada | Estudiar conceptualmente AWS Direct Connect, Azure ExpressRoute y Google Cloud Interconnect; no desplegarlos si el coste no es razonable para el laboratorio. | Pendiente |

El detalle de cada fase se concretara al llegar a ella. La eleccion de VPN
puede requerir BGP desde la Fase 3; revisaremos esa dependencia antes de
implementar para ajustar la secuencia de aprendizaje.

## Estado actual

La VPN mantiene dos tuneles IPsec y dos sesiones BGP. AWS aprende
`10.30.0.0/24` y GCP aprende `10.10.0.0/16`; la conectividad privada entre
`10.10.0.10` y `10.30.0.10` se ha probado en ambos sentidos. Los dos tuneles
terminan deliberadamente en la interfaz `0` del HA VPN gateway, por lo que esta
topologia aun no tiene el modelo HA completo.

La Fase 5 incorpora cuatro flujos de servicio:

- EC2 obtiene credenciales de un instance profile y accede a S3 mediante un
  S3 Gateway Endpoint asociado a su route table.
- La VM de GCP llega por la VPN a un S3 Interface Endpoint de AWS.
- La VM obtiene un identity token OIDC de su metadata server y llama al STS
  Interface Endpoint para asumir un rol AWS y recibir credenciales temporales.
- Durante el arranque, la VM descarga AWS CLI desde Cloud Storage mediante
  Private Google Access y lo instala antes de la administracion por SSH.

La VM de GCP no tiene IP publica ni Cloud NAT. Su ruta explicita
`0.0.0.0/0 -> default-internet-gateway` hace utilizable Private Google Access,
pero no proporciona acceso general a Internet. El trafico destinado a
`10.10.0.0/16` sigue la ruta BGP mas especifica a traves de la VPN.

- AWS account: perfil local `multicloud-lab`, region `eu-west-2`.
- GCP project: `multicloud-lab-prp`, region `europe-west2`.
- Un unico root Terraform en `infra/`.
- State local durante las primeras fases.

La Default VPC de AWS y cualquier otro proyecto GCP quedan fuera de alcance.

## Requisitos

- Terraform `>= 1.16.0, < 2.0.0`
- AWS CLI v2 con una sesion activa para el perfil `multicloud-lab`
- Google Cloud CLI con la configuracion `multicloud-lab`
- Application Default Credentials con quota project `multicloud-lab-prp`
- Un `artifacts/awscliv2.zip` local para publicar AWS CLI en el bucket GCS. El
  binario no se versiona; debe descargarse de AWS y verificarse antes del apply.

## Verificacion segura

Antes de cualquier operacion Terraform:

```bash
./scripts/preflight.sh
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan
```

Tras el despliegue, el plan debe indicar que no hay cambios. Antes de aplicar
nuevas iteraciones revisaremos sus recursos y costes.

`scripts/verify-phase1.sh` conserva valor como comprobacion historica de la
topologia aislada, pero sus expectativas de rutas ya no describen las Fases
3-5. Las pruebas actuales deben correlacionar rutas BGP, estado de endpoints,
identidad asumida y operaciones S3. No se deben imprimir ni conservar tokens
OIDC, access keys temporales o PSKs.

El state local es sensible. Los ficheros existentes deben conservar permisos
`0600`; el preflight falla si detecta permisos mas amplios. El state no tiene
todavia backup remoto, por lo que perder este equipo puede exigir importar los
recursos antes de poder destruirlos de forma segura.

Para eliminar la infraestructura del laboratorio, ejecutar preflight y
`terraform -chdir=infra destroy`, revisando su plan. Las APIs GCP permanecen
habilitadas. Ya se comprobo que un destroy completo elimina tambien las redes,
no solo las VMs; despues debe verificarse el inventario de ambos proveedores.
La comprobacion debe incluir VPNs, VPC endpoints y sus ENIs, buckets y objetos,
roles y instance profiles, discos, rutas y service accounts.

## Conectar a VM de GCP

```bash
gcloud compute ssh multicloud-lab-vm \
  --project=multicloud-lab-prp \
  --zone=europe-west2-a \
  --tunnel-through-iap
```

La autenticacion actual usa claves SSH temporales en metadata. OS Login esta
diferido a una iteracion posterior.

## Conectar a VM de AWS

```bash
aws ec2-instance-connect ssh \
  --instance-id $(terraform -chdir=infra output -raw aws_instance_id) \
  --os-user ec2-user \
  --connection-type eice \
  --eice-options endpointId=$(terraform -chdir=infra output -raw eice_id) \
  --profile multicloud-lab \
  --region eu-west-2
```

Cuando Terraform crea o reemplaza la EC2,
`terraform_data.remove_stale_aws_vm_host_key` elimina de
`~/.ssh/known_hosts` la clave anterior asociada a `10.10.0.10`.
Esto evita conflictos entre distintas encarnaciones de la instancia sin
desactivar `StrictHostKeyChecking`. En la primera conexion a la instancia
nueva, SSH solicita aceptar su nueva clave de host.

La sincronizacion se ejecuta solo cuando cambia el ID de la instancia. Un
`terraform apply` sin cambios y `terraform destroy` no modifican
`known_hosts`.

## Documentacion

- [Preparacion de cuentas](docs/account-preparation.md)
- [Arquitectura](docs/architecture.md)
- [Routing](docs/routing.md)
- [VPN e IPsec](docs/vpn.md)
- [Observabilidad y evidencia](docs/observability.md)
- [Costes](docs/costs.md)
- [Diario del laboratorio](docs/lab-journal.md)
- [Bibliografia y fuentes](docs/references.md)
