# Server setup for entire homelab

This contains a collection of selfhosted Docker Swarm stacks

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="https://upload.wikimedia.org/wikipedia/commons/0/00/Pi-hole_Logo.png" alt="PiHole" width="60"/> <br/>PiHole
      </td>
      </td>
      <td align="center">
        <img src="https://avatars.githubusercontent.com/u/122929872?s=48&v=4" alt="Homepage" width="60"/> <br/>Homepage
      </td>
      <td align="center">
        <img src="https://user-images.githubusercontent.com/8393701/196800928-49cd5781-88b2-40ff-b398-7d335cca24c0.png" alt="ufw" width="60"/> <br/>ufw
      </td>
      <td align="center">
        <img src="https://user-images.githubusercontent.com/8393701/221434420-2277ee82-115d-4ec6-bbe7-d0a010687dda.png" alt="Traefik" width="60"/> <br/>Traefik
      </td>
    </tr>
  </table>
</div>

## Directory structure

### Docker swarm

A NFS share is mounted on `/mnt/shared`.

# Suggested Directory Structure for NAS Optimization

## High-Level Directory Structure

```
/mnt/shared/
├── docker/
│   ├── configs/
│   └── data/
├── bulk_data/
│   └── syncthing/
├── media/
│   ├── personal/
│   │   ├── images/
│   │   └── videos/
│   └── movies/
├── backups/
│   └── restic/
```

## Detailed Breakdown

### 1. Docker Data
- **`/mnt/shared/docker/`**
  - **`configs/`**: Store Docker container configurations here. Each container can have its own subfolder based on the container name or service, making it easy to find and manage.
    ```
    /mnt/shared/docker/configs/
    ├── container1/
    └── container2/
    ```
  - **`data/`**: Store persistent data generated or used by your Docker containers. You can follow a similar approach as `configs`, with each container having its own subfolder. This keeps Docker-related files separate from your personal or bulk data.
    ```
    /mnt/shared/docker/data/
    ├── container1/
    └── container2/
    ```

### 2. Bulk Data
- **`/mnt/shared/bulk_data/`**
  - **`syncthing/`**: Place your Syncthing data here, under a separate directory. This makes it distinct from Docker data, but you can back it up selectively.
    ```
    /mnt/shared/bulk_data/syncthing/
    ```

### 3. Media
- **`/mnt/shared/media/`**
  - **`personal/`**: Personal media like images and videos can be stored here, with separate directories for different media types to keep them organized.
    ```
    /mnt/shared/media/personal/
    ├── images/
    └── videos/
    ```
  - **`movies/`**: Separate your movie or entertainment-related media here, since it can be a large dataset and might not need the same level of backup as personal data.
    ```
    /mnt/shared/media/movies/
    ```

### 4. Backups
- **`/mnt/shared/backups/`**
  - **`restic/`**: Dedicate a directory for Restic backups. Depending on your backup policy, you can target specific directories (e.g., personal data and Docker configs) while excluding others (e.g., movies).
    ```
    /mnt/shared/backups/restic/
    ```

## Additional Suggestions

- **Granularity**: If necessary, you can add more granular subdirectories, especially in the `docker/data` and `media` directories. For example, break down `personal/images` into `photos/`, `screenshots/`, etc., if you need better categorization.
- **Access Control**: Ensure that appropriate access permissions are set for each directory, especially for personal data vs shared media. Docker and Syncthing directories may need different permissions than your personal media.
- **Backup Strategy**: Since Restic allows for exclusions and inclusions, you can set up your Restic backup to target:
  - **To Backup**: `/mnt/shared/docker/configs`, `/mnt/shared/media/personal/`, `/mnt/shared/bulk_data/syncthing`
  - **Exclude**: `/mnt/shared/media/movies`, `/mnt/shared/docker/data` (if it's only temporary or not critical)

This structure should give you a balance of organization, flexibility, and ease of management for backups. You can easily scale or add more directories in the future without breaking this structure.
