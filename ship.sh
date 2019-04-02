app_name=$1
app_version=$2



build_local_project () {
                echo ">>>>>>>>>>>>>>>>>>> BUILDING LOCAL PROJECT"

                if [[ $app_name =~ "persist" ]]; then
                                 mvn clean install -Dspring.profiles.active=dev
                    else
                                 echo "App name does not contain 'persist'. Therefore exiting."
                                 exit 0
                     fi

                    }

docker_process(){
        echo ">>>>>>>>>>>>>>>>>>> DOCKER IMAGE BUILD"

        docker build . -t $app_name:$app_version

        echo ">>>>>>>>>>>>>>>>>>> DOCKER IMAGE TAG"
        docker tag $app_name:$app_version hunaltay/$app_name:$app_version

        echo ">>>>>>>>>>>>>>>>>>> DOCKER IMAGE PUSH"
        docker push hunaltay/$app_name:$app_version


}
openshift_process_route(){
 echo ">>>>>>>>>>>>>>>>>>> OPENSHIFT: CREATE ROUTE"

         oc create route edge --service=$app_name \
                              --insecure-policy='Redirect' \
                              --port=8444-tcp

}


openshift_process(){
              echo ">>>>>>>>>>>>>>>>>>> OPENSHIFT: CREATE APP"

              oc delete all --selector app=$app_name

              oc new-app hunaltay/$app_name:$app_version

              openshift_process_route



}
configmap_process(){
if [[ $app_name =~ "persist" ]]; then
     echo ">>>>>>>>>>>>>>>>>>> OPENSHIFT: CREATE ConfigMap "

 GEN_CONFIG=$(sed  '/^\s*$/d'  config/application-pr.properties \
             | grep -v "PASSWORD" | grep -v "USER" \
             | sed -e 's/^/--from-literal=/' | tr "\n" ' ')



    if [ "X$GEN_CONFIG" = "X" ]; then
        echo "No config found for prlooking config/application-pr.properties"
        echo "Exting!"
        exit 1
    fi

    oc delete configmap $app_name-config   -n helpfularmy
    oc create configmap $app_name-config  $GEN_CONFIG   -n helpfularmy
    oc label  configmap $app_name-config   app=$app_name -n helpfularmy

    echo ">>>>>>>>>>>>>>>>>>> OPENSHIFT: CREATE ENV VARIABLES "
    oc set env dc/$app_name --from configmap/$app_name-config
fi

}
secrets_process(){
if [[ $app_name =~ "persist" ]]; then
     echo ">>>>>>>>>>>>>>>>>>> OPENSHIFT: CREATE Secrets file "

  GEN_SECRET=$(grep '^MYSQL' config/application-pr.properties | grep -v "DATABASE" | grep -v "HOST" | grep -v "PORT"  | sed -e 's/^/--from-literal=/' | tr "\n" ' ')

    if [ "X$GEN_SECRET" = "X" ]; then
        echo "No config found for prlooking config/application-pr.properties"
        echo "Exting!"
        exit 1
    fi

    oc delete secret $app_name-secret  -n helpfularmy
    oc create secret generic $app_name-secret  $GEN_SECRET   -n helpfularmy
    oc label  secret $app_name-secret   app=$app_name -n helpfularmy

    echo ">>>>>>>>>>>>>>>>>>> OPENSHIFT: CREATE ENV VARIABLES using Secrets"
    oc set env dc/$app_name --from secret/$app_name-secret

fi
}
if [[ -n "$app_name" ]]; then
        if [[ -n "$app_version" ]]; then

            oc project helpfularmy

            build_local_project



            if [[ -n "$recreate" ]]; then

            delete_project

            create_project

            else
                echo "Countinue without re-creating helpfularmy project"
            fi


        docker_process

        openshift_process

        configmap_process

        secrets_process

        else
            echo "Put the app version"
        fi
else
    echo "Put the app name"
fi

