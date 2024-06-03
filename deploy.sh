_rosadeploy() {
    _rosaenv
    _rosareplicas

    if [[ -z "${ROSA_VISIBILITY}" ]]; then
        echo "missing ROSA_VISIBILITY or variable is set to empty string"
        return
    fi

    pushd ~/terraform.d/rosa

    mkdir -p $ROSA_CLUSTER_NAME
    cp -f ${ROSA_VISIBILITY}.tf $ROSA_CLUSTER_NAME/main.tf
    cd $ROSA_CLUSTER_NAME/

    ROSA_PASSWORD="$(bw get password rosa-admin-password)"
    
    terraform init
    terraform apply \
        -var="cluster_name=$ROSA_CLUSTER_NAME" \
        -var="token=$(bw get password ocm-api-key)" \
        -var="multi_az=$ROSA_MULTI_AZ" \
        -var="ocp_version=$ROSA_CLUSTER_OCP_VERSION" \
        -var="admin_password=$ROSA_PASSWORD" \
        -var="developer_password=$ROSA_PASSWORD"

    popd
}