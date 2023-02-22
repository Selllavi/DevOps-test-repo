# Weather Helm Chart

Helm chart to deploy weather project services.

Parallel deployments in one namespace are supported, use "**instance**" input variable to define resource suffix.

# Contents

- [Usage](#usage)
- [License](#license)

# Usage

To deploy weather app:

```yaml
instance: dev
imageTag: 1.0
```

To install locally use command

```yaml
helm install <instance-name> helm-charts
```
where `<instance-name>` is your instance name for helm release, e.g `dev-weather`.

# Licence
The chart is distributed under MIT Licence
