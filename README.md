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

**Estado actual: Fases 0, 1 y 2 completadas. Fase 3 pendiente.** Las fases posteriores son una hoja de ruta, no una autorizacion
para desplegarlas.

| Fase | Trabajo y objetivo | Estado |
| --- | --- | --- |
| 0 — Preparacion de cuentas | Preparar cuentas AWS y GCP, credenciales, aislamiento, presupuestos y providers Terraform; verificar identidades y un plan sin cambios. | Completada |
| 1 — Redes del laboratorio | Definir el modelo de subredes y crear una VPC propia en AWS y una VPC propia en GCP; verificar direccionamiento y aislamiento. | Completada |
| 2 — VMs y routing local | Crear una VM minima en cada cloud y estudiar las rutas locales y los controles de acceso. | Completada |
| 3 — VPN Site-to-Site | Elegir y configurar una VPN IPsec AWS ↔ GCP con un enfoque pedagogico; entender gateways, tuneles y rutas. | Pendiente |
| 4 — Conectividad privada | Probar comunicacion entre IPs privadas y verificar las rutas y reglas que la permiten. | Pendiente |
| 5 — Observabilidad | Incorporar Flow Logs, logs y metricas para correlacionar conexiones y obtener evidencia del recorrido del trafico. | Pendiente |
| 6 — Trafico privado e Internet | Comparar conexiones hacia la otra cloud y hacia Internet, demostrando la ruta utilizada en cada caso. | Pendiente |
| 7 — BGP | Introducir o profundizar en el intercambio dinamico de rutas y compararlo con routing estatico, segun la VPN elegida. | Pendiente |
| 8 — Diagnostico de fallos | Provocar fallos controlados de routing y VPN, diagnosticarlos mediante logs y metricas y recuperar la conectividad. | Pendiente |
| 9 — Azure | Preparar Azure e incorporar una VNet con CIDR `10.20.0.0/16` a la conectividad privada. | Pendiente |
| 10 — Arquitecturas avanzadas | Estudiar hub-and-spoke y transit routing con AWS Transit Gateway, Azure Virtual WAN y GCP Network Connectivity Center; revisar costes antes de cualquier despliegue. | Pendiente |
| 11 — Conectividad dedicada | Estudiar conceptualmente AWS Direct Connect, Azure ExpressRoute y Google Cloud Interconnect; no desplegarlos si el coste no es razonable para el laboratorio. | Pendiente |

El detalle de cada fase se concretara al llegar a ella. La eleccion de VPN
puede requerir BGP desde la Fase 3; revisaremos esa dependencia antes de
implementar para ajustar la secuencia de aprendizaje.

## Estado actual

La Fase 2 mantiene las redes IPv4 aisladas y anade una VM privada en cada
cloud: AWS `10.10.0.10` y GCP `10.30.0.10`. Ninguna tiene IP publica ni una
ruta cloud por defecto hacia Internet. El acceso administrativo usa EC2
Instance Connect Endpoint en AWS e IAP TCP forwarding en GCP. Todavia no hay
VPN ni conectividad entre clouds. El coste conjunto estimado mientras ambas
VMs y discos estan activos es de aproximadamente `EUR 0,30-0,45/dia`.

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

## Verificacion segura

Antes de cualquier operacion Terraform:

```bash
./scripts/preflight.sh
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan
./scripts/verify-phase1.sh
```

Tras el despliegue, el plan debe indicar que no hay cambios. Antes de aplicar
nuevas iteraciones revisaremos sus recursos y costes.

El state local es sensible. Los ficheros existentes deben conservar permisos
`0600`; el preflight falla si detecta permisos mas amplios. El state no tiene
todavia backup remoto, por lo que perder este equipo puede exigir importar los
recursos antes de poder destruirlos de forma segura.

Para eliminar la infraestructura del laboratorio, ejecutar preflight y
`terraform -chdir=infra destroy`, revisando su plan. Las APIs GCP permanecen
habilitadas. Ya se comprobo que un destroy completo elimina tambien las redes,
no solo las VMs; despues debe verificarse el inventario de ambos proveedores.

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
  --instance-id <instance-id> \
  --os-user ec2-user \
  --connection-type eice \
  --eice-options endpointId=<eice-id> \
  --profile multicloud-lab \
  --region eu-west-2
```

## Documentacion

- [Preparacion de cuentas](docs/account-preparation.md)
- [Arquitectura](docs/architecture.md)
- [Routing](docs/routing.md)
- [Costes](docs/costs.md)
- [Diario del laboratorio](docs/lab-journal.md)
