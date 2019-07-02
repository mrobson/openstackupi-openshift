oc delete secret/kubeadmin -n kube-system
oc create secret generic kubeadmin -n kube-system --from-literal=kubeadmin="$(htpasswd -bnBC 10 "" '5char-5char-5char-5char' | tr -d ':\n')"
echo "kubeadmin password set to '5char-5char-5char-5char'"
