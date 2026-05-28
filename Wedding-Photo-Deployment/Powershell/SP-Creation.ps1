az login --tenant fbdf800e-c040-4258-9ad3-6bbfb164500d

$sub = (az account show --query id -o tsv)
az ad sp create-for-rbac --name "tf-memtly-sp" --role Contributor --scopes /subscriptions/$sub/resourceGroups/Memtly-Deployment