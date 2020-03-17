cd bin
#登录root
./kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user root --password root

realmName='springboot-integration'
#删除存在的realm,这样下面的client/user/roles都会删除
./kcadm.sh delete realms/$realmName -r $realmName

#创建realm
realmId=$(./kcadm.sh create realms -s realm=$realmName -s enabled=true  2>&1 | awk -F "'" '{print $2}')

#创建换token的公开client
openClientName='springboot-security'
#为了调试方便，直接指定secret code
openSecret='d0b8122f-8dfb-46b7-b68a-f5cc4e25d000'
#openClient=$(./kcadm.sh create clients -r $realmId -s clientId=$openClientName -s enabled=true -s publicClient=true -s 'redirectUris=["http://localhost:9090/*","http://127.0.0.1:9090/*"]' -s baseUrl=http://localhost:9090 -s adminUrl=http://localhost:9090 -s directAccessGrantsEnabled=true 2>&1 | awk -F "'" '{print $2}')
openClient=$(./kcadm.sh create clients -r $realmId -s clientId=$openClientName -s enabled=true -s publicClient=true -s  'redirectUris=["http://localhost:9090/*","http://127.0.0.1:9090/*"]' -s baseUrl=http://localhost:9090 -s adminUrl=http://localhost:9090 -s clientAuthenticatorType=client-secret -s secret=$openSecret -s directAccessGrantsEnabled=true 2>&1 | awk -F "'" '{print $2}')


#创建受保护的client
restClientName='springboot-rest-api'
#为了调试方便，直接指定secret code
restSecret='6e32611b-8e10-4afe-ac0b-0f64c4022390'
restClient=$(./kcadm.sh create clients -r $realmId -s clientId=$restClientName -s enabled=true  -s baseUrl=http://localhost:9091 -s bearerOnly=true -s secret=$restSecret  2>&1 | awk -F "'" '{print $2}')

#显示client清单
echo "10."$realmId" clients: "
./kcadm.sh get clients -r $realmName  --fields id,clientId

#删除realm的角色admin/user :没有realm的roles
# ./kcadm.sh delete roles/admin -r $realmId
# ./kcadm.sh delete roles/user -r $realmId

#删除restClient的角色admin/user
# echo "15.删除restClient角色admin/user "$restClient
# ./kcadm.sh delete clients/$restClient/roles/admin -r $realmId
# ./kcadm.sh delete clients/$restClient/roles/user -r $realmId

#给realm创建roles
echo "17.给"$realmId"创建两个角色 "
./kcadm.sh create roles -r $realmId -s name=user -s "description=$realmId user role"
./kcadm.sh create roles -r $realmId -s name=admin -s "description=$realmId admin role"

#给受保护的client创建两个角色
# echo "20.给受保护的client创建两个角色 "
# ./kcadm.sh create clients/$restClient/roles -r $realmId -s name=admin -s "description=$restClient Admin role" #字符串中引用变量要用双引号
# ./kcadm.sh create clients/$restClient/roles -r $realmId -s name=user  -s "description=$restClient User role"

#显示realm的roles清单
echo "25.realm: "$realmId" 的roles: "
./kcadm.sh get roles -r $realmId

#显示client的roles清单
echo "30.restClient: "$restClient" 的roles: "
./kcadm.sh get clients/$restClient/roles -r $realmId

#查看受保护的client配置
echo "35.restClient: "$restClient" 的配置情况: "
./kcadm.sh get clients/$restClient/installation/providers/keycloak-oidc-keycloak-json -r $realmId

# #删除admin/user用户
# adminId=$(./bin/kcadm.sh get users -r $realmId -q username=admin 2>&1 | jq -r '.[0].id')
# ./kcadm.sh delete users/$adminId -r $realmId

# userId=$(./bin/kcadm.sh get users -r $realmId -q username=user 2>&1 | jq -r '.[0].id')
# ./kcadm.sh delete users/$userId -r $realmId

#创建管理员账号，归realm
adminId=$(./kcadm.sh create users -r $realmId -s username=admin -s firstName=wu -s lastName=Wang -s email=admin@mail.xx.com  -s enabled=true   2>&1 | awk -F "'" '{print $2}')
#设置密码
./kcadm.sh update users/$adminId/reset-password -r $realmId -s type=password -s value=123456 -s temporary=false -n
#设置client的角色
#./kcadm.sh add-roles -r $realmId --uusername=admin --cclientid $restClientName --rolename admin
#设置为realm的角色
./kcadm.sh add-roles --uusername admin --rolename admin -r $realmId

#创建普通用户账号，归realm
userId=$(./kcadm.sh create users -r $realmId -s username=user -s firstName=san -s lastName=Zhang -s email=user@mail.xx.com -s enabled=true  2>&1 | awk -F "'" '{print $2}')
#设置密码
./kcadm.sh update users/$userId/reset-password -r $realmId -s type=password -s value=123456 -s temporary=false -n
#设置client的角色
#./kcadm.sh add-roles -r $realmId --uusername=user --cclientid $restClientName --rolename user
#设置为realm的角色
./kcadm.sh add-roles --uusername user --rolename user -r $realmId

#查看realm的user清单
echo "40."$realmId" 的users: "
./kcadm.sh get users -r $realmId --offset 0 --limit 1000

#获得访问token
export adminToken=$(curl -ss --data "grant_type=password&client_id=$openClientName&client_secret=$openSecret&username=admin&password=123456" http://localhost:8080/auth/realms/$realmId/protocol/openid-connect/token | jq -r .access_token)
export userToken=$(curl -ss --data "grant_type=password&client_id=$openClientName&client_secret=$openSecret&username=user&password=123456" http://localhost:8080/auth/realms/$realmId/protocol/openid-connect/token | jq -r .access_token)
 

echo "\n\nAdmin user's Token:\n "$adminToken
echo "\n\nUser user's Token:\n "$userToken

#显示变量
echo "\n\n     realmName: "$realmId
echo "\n  openClientID: "$openClient
echo "\nopenClientName: "$openClientName
echo "\n  restClientID: "$restClient
echo "\nrestClientName: "$restClientName
echo "\n       adminId: "$adminId
echo "\n        userId: "$userId

echo "\n\nAPI访问测试： "
echo "\n『adminToken+admin』 result : "
curl -H "Authorization: bearer $adminToken" http://localhost:9091/admin
echo "\n\n『adminToken+user』 result : "
curl -H "Authorization: bearer $adminToken" http://localhost:9091/user
echo "\n\n『userToken+admin』 result : "
curl -H "Authorization: bearer $userToken" http://localhost:9091/admin
echo "\n\n『userToken+user』 result : "
curl -H "Authorization: bearer $userToken" http://localhost:9091/user
