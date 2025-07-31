# HomeLab To-Do List & Milestones

## Milestones
- [ ] Cluster infrastructure fully automated with GitOps
- [ ] All core apps deployed and accessible via Ingress
- [ ] Internal DNS and HTTPS (cert-manager) configured
- [ ] Monitoring and alerting in place (Prometheus, Alertmanager, Discord notifications)
- [ ] Documentation and cheat sheets completed for all major tools
- [ ] Deploy external secrets
- [ ] Configure ISCI for volume mounts from TrueNas

---

## To-Do List

### Cluster & Infrastructure
- [ ] Review and update Talos machine configs for all nodes
- [ ] Validate MetalLB and NGINX Ingress setup
- [ ] Automate cluster bootstrap and upgrades
- [ ] Test backup and recovery procedures

### App Deployments
- [ ] Migrate existing containers to Kubernetes
- [ ] Validate Ingress routing and DNS for all apps
- [ ] Set up persistent storage for stateful apps

### Networking & Security
- [ ] Set up cert-manager for HTTPS on internal services

### Monitoring & GitOps
- [ ] Enable FluxCD notifications to Discord
- [ ] Integrate Prometheus and Grafana for metrics
- [ ] Document troubleshooting commands and workflows

### Documentation
- [ ] Finalize cheat sheets for Kubernetes, TalosCTL, FluxCD
- [ ] Create onboarding guide for new users
- [ ] Maintain up-to-date README and architecture diagrams

---

> Update this list as you complete tasks or add new goals. Check off milestones as you progress!
