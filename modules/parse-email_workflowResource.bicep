param workflowResourceName string
param location string
param functionAppResourceID string

resource workflowResource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflowResourceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        For_each_attachment: {
          actions: {
            Compose_ExtractEmailsFunction_Input: {
              inputs: {
                strings: '@body(\'Get_line_with_From\')'
              }
              runAfter: {
                Get_line_with_From: [
                  'Succeeded'
                ]
              }
              type: 'Compose'
            }
            Compose_ExtractURLsFunction_Input: {
              inputs: {
                strings: '@body(\'Get_lines_with_links\')'
              }
              runAfter: {
                Get_lines_with_links: [
                  'Succeeded'
                ]
              }
              type: 'Compose'
            }
            Condition: {
              actions: {
                Reset_variable_on_true: {
                  inputs: {
                    name: 'attachment_as_array'
                    value: []
                  }
                  runAfter: {}
                  type: 'SetVariable'
                }
                Split_to_array: {
                  inputs: {
                    name: 'attachment_as_array'
                    value: '@split(body(\'Get_attachment\'), \'\n\')'
                  }
                  runAfter: {
                    Reset_variable_on_true: [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                }
              }
              else: {
                actions: {
                  Reset_variable_on_false: {
                    inputs: {
                      name: 'attachment_as_array'
                      value: []
                    }
                    runAfter: {}
                    type: 'SetVariable'
                  }
                  Split_to_array_after_decoding: {
                    inputs: {
                      name: 'attachment_as_array'
                      value: '@split(base64ToString(body(\'Get_attachment\')[\'$content\']), \'\n\')'
                    }
                    runAfter: {
                      Reset_variable_on_false: [
                        'Succeeded'
                      ]
                    }
                    type: 'SetVariable'
                  }
                }
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@outputs(\'Get_attachment\')[\'headers\'][\'Content-Type\']'
                      'text/plain'
                    ]
                  }
                ]
              }
              runAfter: {
                Get_attachment: [
                  'Succeeded'
                ]
              }
              type: 'If'
            }
            ExtractEmailsFunction: {
              inputs: {
                body: '@outputs(\'Compose_ExtractEmailsFunction_Input\')'
                function: {
                  id: '${functionAppResourceID}/ExtractEmailsFunction'
                }
              }
              runAfter: {
                Compose_ExtractEmailsFunction_Input: [
                  'Succeeded'
                ]
              }
              type: 'Function'
            }
            ExtractURLsFunction: {
              inputs: {
                body: '@outputs(\'Compose_ExtractURLsFunction_Input\')'
                function: {
                  id: '${functionAppResourceID}/ExtractURLsFunction'
                }
              }
              runAfter: {
                Compose_ExtractURLsFunction_Input: [
                  'Succeeded'
                ]
              }
              type: 'Function'
            }
            Get_attachment: {
              inputs: {
                authentication: {
                  audience: 'https://graph.microsoft.com'
                  type: 'ManagedServiceIdentity'
                }
                method: 'GET'
                uri: 'https://graph.microsoft.com/v1.0/users/1f62e3c9-1ba3-42ff-821f-6527f6882e75/messages/@{triggerBody()?[\'id\']}/attachments/@{items(\'For_each_attachment\')?[\'id\']}/$value'
              }
              runAfter: {}
              type: 'Http'
            }
            Get_line_with_From: {
              inputs: {
                from: '@variables(\'attachment_as_array\')'
                where: '@contains(item(), \'From:\')'
              }
              runAfter: {
                Condition: [
                  'Succeeded'
                ]
              }
              type: 'Query'
            }
            Get_line_with_Subject: {
              inputs: {
                from: '@variables(\'attachment_as_array\')'
                where: '@contains(item(), \'Subject:\')'
              }
              runAfter: {
                Set_from_line: [
                  'Succeeded'
                ]
              }
              type: 'Query'
            }
            Get_lines_with_links: {
              inputs: {
                from: '@variables(\'attachment_as_array\')'
                where: '@contains(item(), \'http\')'
              }
              runAfter: {
                Set_subject_line: [
                  'Succeeded'
                ]
              }
              type: 'Query'
            }
            Set_from_line: {
              inputs: {
                name: 'from_line'
                value: '@body(\'ExtractEmailsFunction\')'
              }
              runAfter: {
                ExtractEmailsFunction: [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
            }
            Set_link_lines: {
              inputs: {
                name: 'link_lines'
                value: '@body(\'ExtractURLsFunction\')'
              }
              runAfter: {
                ExtractURLsFunction: [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
            }
            Set_subject_line: {
              inputs: {
                name: 'subject_line'
                value: '@body(\'Get_line_with_Subject\')'
              }
              runAfter: {
                Get_line_with_Subject: [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
            }
          }
          foreach: '@body(\'Parse_JSON\')?[\'value\']'
          runAfter: {
            Initialize_link_lines: [
              'Succeeded'
            ]
          }
          runtimeConfiguration: {
            concurrency: {
              repetitions: 1
            }
          }
          type: 'Foreach'
        }
        Initialize_attachment_as_array: {
          inputs: {
            variables: [
              {
                name: 'attachment_as_array'
                type: 'array'
              }
            ]
          }
          runAfter: {
            Parse_JSON: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        Initialize_from_line: {
          inputs: {
            variables: [
              {
                name: 'from_line'
                type: 'array'
              }
            ]
          }
          runAfter: {
            Initialize_attachment_as_array: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        Initialize_link_lines: {
          inputs: {
            variables: [
              {
                name: 'link_lines'
                type: 'array'
              }
            ]
          }
          runAfter: {
            Initialize_subject_line: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        Initialize_subject_line: {
          inputs: {
            variables: [
              {
                name: 'subject_line'
                type: 'array'
              }
            ]
          }
          runAfter: {
            Initialize_from_line: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        List_attachments: {
          inputs: {
            authentication: {
              audience: 'https://graph.microsoft.com'
              type: 'ManagedServiceIdentity'
            }
            method: 'GET'
            uri: 'https://graph.microsoft.com/v1.0/users/1f62e3c9-1ba3-42ff-821f-6527f6882e75/messages/@{triggerBody()?[\'id\']}/attachments'
          }
          runAfter: {}
          type: 'Http'
        }
        Parse_JSON: {
          inputs: {
            content: '@body(\'List_attachments\')'
            schema: {
              properties: {
                '@@odata.context': {
                  type: 'string'
                }
                value: {
                  items: {
                    properties: {
                      '@@odata.type': {
                        type: 'string'
                      }
                      contentType: {
                        type: 'string'
                      }
                      id: {
                        type: 'string'
                      }
                      isInline: {
                        type: 'boolean'
                      }
                      lastModifiedDateTime: {
                        type: 'string'
                      }
                      name: {
                        type: 'string'
                      }
                      size: {
                        type: 'integer'
                      }
                    }
                    required: [
                      '@@odata.type'
                      'id'
                      'lastModifiedDateTime'
                      'name'
                      'contentType'
                      'size'
                      'isInline'
                    ]
                    type: 'object'
                  }
                  type: 'array'
                }
              }
              type: 'object'
            }
          }
          runAfter: {
            List_attachments: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_new_email_arrives: {
          inputs: {
            fetch: {
              method: 'get'
              pathTemplate: {
                template: '/v3/Mail/OnNewEmail'
              }
              queries: {
                fetchOnlyWithAttachment: true
                folderPath: 'Inbox'
                importance: 'Any'
                includeAttachments: true
                subjectFilter: 'PHISING'
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            subscribe: {
              body: {
                NotificationUrl: '@{listCallbackUrl()}'
              }
              method: 'post'
              pathTemplate: {
                template: '/GraphMailSubscriptionPoke/$subscriptions'
              }
              queries: {
                fetchOnlyWithAttachment: true
                folderPath: 'Inbox'
                importance: 'Any'
              }
            }
          }
          splitOn: '@triggerBody()?[\'value\']'
          type: 'ApiConnectionNotification'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          office365: {
            connectionId: '/subscriptions/8194f7dc-68ee-4dff-a67e-b01eec9ed54d/resourceGroups/parse-email-panats_group/providers/Microsoft.Web/connections/office365'
            connectionName: 'office365'
            id: '/subscriptions/8194f7dc-68ee-4dff-a67e-b01eec9ed54d/providers/Microsoft.Web/locations/westeurope/managedApis/office365'
          }
        }
      }
    }
  }
}

output workflowIdentity string = workflowResource.identity.principalId
