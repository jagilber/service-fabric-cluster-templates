param resourceId_Microsoft_ManagedIdentity_userAssignedIdentities_parameters_userAssignedIdentityName object
param variables_keyVaultName ? /* TODO: fill in correct type */

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
@allowed([
  'all'
  'backup'
  'create'
  'decrypt'
  'delete'
  'encrypt'
  'get'
  'getrotationpolicy'
  'import'
  'list'
  'purge'
  'recover'
  'release'
  'restore'
  'rotate'
  'setrotationpolicy'
  'sign'
  'unwrapKey'
  'update'
  'verify'
  'wrapKey'
])
param keysPermissions array

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
@allowed([
  'all'
  'backup'
  'delete'
  'get'
  'list'
  'purge'
  'recover'
  'restore'
  'set'
])
param secretsPermissions array

@description('Specifies the permissions to certificates in the vault. Valid values are: all,  create, delete, update, deleteissuers, get, getissuers, import, list, listissuers, managecontacts, manageissuers,  recover, backup, restore, setissuers, and purge.')
@allowed([
  'all'
  'backup'
  'create'
  'delete'
  'deleteissuers'
  'get'
  'getissuers'
  'import'
  'list'
  'listissuers'
  'managecontacts'
  'manageissuers'
  'purge'
  'recover'
  'restore'
  'setissuers'
  'update'
])
param certificatePermissions array

resource variables_keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${variables_keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: resourceId_Microsoft_ManagedIdentity_userAssignedIdentities_parameters_userAssignedIdentityName.principalId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
          certificates: certificatePermissions
        }
      }
    ]
  }
}