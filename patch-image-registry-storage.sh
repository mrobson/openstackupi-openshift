oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"filesystem":{"volumeSource": {"emptyDir":{}}}}}}'
