# OpenEMS Docker Environment

This repository automatically builds and publishes a standalone Docker image containing the [OpenEMS](https://openems.de/) electromagnetic field solver and its Python bindings.

The image is automatically built and published to the GitHub Container Registry (GHCR) whenever the `Dockerfile` is updated, or when manually triggered via the Actions tab.

## How to use this image in your projects

You don't need to rebuild OpenEMS locally. Just pull the pre-compiled image directly from this repository's registry.

### Local Usage

To run the OpenEMS environment locally and map it to your current working directory:

```bash
docker run -it -v $(pwd):/opt/openems_sim ghcr.io/cbeiraod/openems-docker-env:latest bash
```

### In GitHub Actions (CI)

To use this pre-built environment in the CI pipelines of your other projects, reference it like this:

```yaml
jobs:
  test-simulations:
    runs-on: ubuntu-latest
    container:
      # Automatically pull the environment from GHCR
      image: ghcr.io/cbeiraod/openems-docker-env:latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Run Simulation
        run: |
          pip3 install -r requirements.txt
          python3 your_simulation_script.py
```

Once you push this to your new repo, GitHub Actions will automatically handle the rest! You will see a "Packages" section appear on your repository's right-hand sidebar once the build completes.