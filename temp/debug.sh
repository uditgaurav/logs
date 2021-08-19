#!/bin/bash

echo "#############################################################"
echo "############ Getting pods in Chaos Namespace ################"
echo "#############################################################"
echo 
echo "kubectl get pods -n ${CHAOS_NAMESPACE}"
kubectl get pods -n ${CHAOS_NAMESPACE} || true
echo
echo "###################################################################"
echo "############ Getting pods in Application Namespace ################"
echo "###################################################################"
echo
echo "kubectl get pods -n ${APP_NS}"
kubectl get pods -n ${APP_NS} || true
echo
echo "################################################################"
echo "############ Getting Chaos Resource Information ################"
echo "################################################################"
echo
echo "kubectl get chaosengine,chaosexperiment,chaosresult -n ${CHAOS_NAMESPACE}"
kubectl get chaosengine,chaosexperiment,chaosresult -n ${CHAOS_NAMESPACE} || true
echo
echo "################################################################"
echo "############ Getting Service Account Information ################"
echo "################################################################"
echo
echo "kubectl get sa -n ${CHAOS_NAMESPACE}"
kubectl get sa -n ${CHAOS_NAMESPACE} || true
echo
echo "###################################################"
echo "############ Describe ChaosEngine  ################"
echo "###################################################"
echo
echo "kubectl describe chaosengine -n ${CHAOS_NAMESPACE}"
kubectl describe chaosengine -n ${CHAOS_NAMESPACE} || true
echo
echo "###################################################"
echo "############ Describe ChaosResult  ################"
echo "###################################################"
echo
echo "kubectl describe chaosresult -n ${CHAOS_NAMESPACE}"
kubectl describe chaosresult -n ${CHAOS_NAMESPACE} || true
echo
echo "####################################################"
echo "############ Printing Operator logs ################"
echo "####################################################"
echo
operator_name=$(kubectl get pods -n litmus -l app.kubernetes.io/component=operator --no-headers | awk '{print$1}')
kubectl logs $operator_name -n litmus > logs.txt
cat logs.txt
echo
