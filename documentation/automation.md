# Volunteers for Salesforce Automation Inventory

## Key Workflows

This section describes the key workflows for developers, QEs, and technical
writers.

| Workflow                   | Flow                 | Org Type       | Managed | Namespace       | NPSP |
| -------------------------- | -------------------- | -------------- | ------- | --------------- | ---- |
| Development                | `dev_org`            | dev            |         |                 |      |
| Development (Namespaced)   | `dev_org_namespaced` | dev_namespaced |         | `GW_Volunteers` |      |
| QA                         | `qa_org`             | dev            |         |                 |      |
| Regression                 | `regression_org`     | regression     | ✔       |                 |      |
| Customer Install           | `customer_org`       | beta           | ✔       |                 |      |
| Customer Install with NPSP | `customer_org_npsp`  | beta           | ✔       |                 | ✔    |

## Utility Tasks and Flows

| Name           | Type | Purpose                                                          |
| -------------- | ---- | ---------------------------------------------------------------- |
| `install_npsp` | Flow | Install NPSP with relationship configuration and trial metadata. |


## Unpackaged Metadata

Unpackaged directory structure:

```
unpackaged
└── config
    ├── delete
    ├── dev
    ├── npsp_v4s_layouts
    ├── qa
    └── v4s_only_layouts
```

Each directory is used as follows:

| Directory           | Purpose                                       | Deploy task                    | Retrieve task |
| ------------------- | --------------------------------------------- | ------------------------------ | ------------- |
| `dev/`              | Profiles, Permission Sets, and Sites          | `deploy_dev_config`            |               |
| `qa/`               | Contact layout for QA                         | `deploy_qa_config`             |               |
| `delete/`           | remove stock layouts                          | `deploy_delete_config`         |               |
| `npsp_v4s_layouts/` | Page layouts for an org with NPSP and V4S     | `deploy_npsp_v4s_page_layouts` |               |
| `v4s_only_layouts/` | Page layouts for an org with V4S but not NPSP | `deploy_v4s_only_page_layouts` |               |

# Test Data

V4S includes a comprehensive data set intended for QA and regression testing. Test data is automatically deployed in dev, QA, and regression orgs.
