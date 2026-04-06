# LFS — Référence projet
#### ATTENTION : NE PAS EXECUTER DE SCRIPT SUR LA MACHINE
> Documentation complète : `rapport_lfs.md`

## État d'avancement

| Étape | Statut |
|---|---|
| Machine hôte Debian + sudo | ✅ |
| Dépendances hôte installées | ✅ |
| Partition `/dev/sda3` 15 Go, montée sur `/mnt/lfs` | ✅ |
| Structure de répertoires `$LFS` | ✅ |
| Utilisateur `lfs` + permissions | ✅ |
| Environnement bash isolé (`.bash_profile` / `.bashrc`) | ✅ |
| Binutils 2.46.0 (pass 1) | ✅ |
| GCC 15.2.0 (pass 1) | ✅ |
| Linux API Headers 6.18.10 | ✅ |
| Glibc 2.43 | ✅ |
| Libstdc++ (§5.6) | 🔧 script prêt (`03_temp_tools.sh`) |
| M4, Ncurses, Bash, Coreutils (§6.2–6.5) | 🔧 script prêt (`03_temp_tools.sh`) |
| Diffutils, File, Findutils, Gawk, Grep, Gzip, Make, Patch, Sed, Tar, Xz (§6.6–6.16) | 🔧 script prêt (`03_temp_tools.sh`) |
| Binutils pass 2 (§6.17) | 🔧 script prêt (`03_temp_tools.sh`) |
| GCC pass 2 (§6.18) | 🔧 script prêt (`03_temp_tools.sh`) |
| Changement de proprio + montages virtuels (§7.2–7.3) | 🔧 script prêt (`04_chroot_prep.sh`) |
| Entrée dans le chroot (§7.4) | 🔧 script prêt (`04_chroot_prep.sh enter`) |
| Structure FHS + fichiers essentiels (§7.5–7.6) | 🔧 script prêt (`04_chroot_prep.sh`) |
| Gettext, Bison, Perl, Python, Texinfo, Util-linux (§7.7–7.12) | 🔧 script prêt (`05_chroot_tools.sh`) |
| Construction du système final (Chapitre 8) | 🔧 script prêt (`06_system_build.sh`) |
| Configuration système (Chapitre 9) | 🔧 script prêt (`07_system_config.sh`) |
| Kernel + GRUB (Chapitre 10) | 🔧 script prêt (`08_kernel_boot.sh`) |
| Démontage + reboot (Chapitre 11) | 🔧 script prêt (`09_unmount.sh`) |

## Ordre d'exécution des scripts

```
# Sur l'hôte (en tant que root) :
bash scripts/01_host_setup.sh
su - lfs
bash scripts/02_toolchain.sh    # Binutils/GCC pass1, Glibc, Libstdc++
bash scripts/03_temp_tools.sh   # Outils temporaires (ch.6)
exit                             # quitter session lfs
bash scripts/04_chroot_prep.sh  # Montages VFS, structure FHS
bash scripts/04_chroot_prep.sh enter  # Entrée dans le chroot

# Dans le chroot :
bash /sources/scripts/05_chroot_tools.sh  # §7.7-7.13
bash /sources/scripts/06_system_build.sh  # Chapitre 8 (83 paquets)
bash /sources/scripts/07_system_config.sh # Chapitre 9
bash /sources/scripts/08_kernel_boot.sh   # Chapitre 10 (kernel + GRUB)
exit                                        # quitter le chroot

# Retour sur l'hôte (root) :
bash scripts/09_unmount.sh
reboot
```

> **Important** : Les scripts 05→08 sont conçus pour s'exécuter **dans le chroot**,
> pas sur l'hôte. Les scripts sont accessibles dans le chroot sous `/sources/scripts/`.
> Avant d'exécuter `08_kernel_boot.sh`, adapter `ROOT_DEV` et `GRUB_DISK`.

## Variables d'environnement critiques

À redéfinir après chaque redémarrage avant toute opération :

```bash
export LFS=/mnt/lfs
mount -v -t ext4 /dev/sda3 $LFS
su - lfs   # puis source ~/.bash_profile dans la session lfs
```

## Pièges connus

- **`$LFS` vide** : exécuter `ln -sv usr/$i $LFS/$i` sans `$LFS` défini écrase `/usr/bin` sur le système hôte. Toujours vérifier `echo $LFS` en premier.
- **`msgfmt` manquant** lors de la compilation Glibc : normal, sans conséquence.
- **Redémarrage** : la variable `LFS` et le montage de `/dev/sda3` sont perdus — les reconfigurer avant de reprendre.
- **Scripts 05→08 dans le chroot uniquement** : les exécuter depuis l'hôte est destructeur — ils modifient `/usr`, `/etc`, etc. sans préfixe `$LFS`.
- **`ROOT_DEV` dans `08_kernel_boot.sh`** : défaut `/dev/sda2`, à corriger en `/dev/sda3` (notre partition LFS). Vérifier aussi `GRUB_PART_NUM=3`.
- **Scripts pas encore dans le chroot** : les copier dans `$LFS/sources/scripts/` avant d'entrer dans le chroot (`cp -r scripts/ $LFS/sources/`).

## Versions utilisées

| Paquet | Version |
|---|---|
| Binutils | 2.46.0 |
| GCC | 15.2.0 |
| GMP | 6.3.0 |
| MPFR | 4.2.2 |
| MPC | 1.3.1 |
| Linux kernel (headers) | 6.18.10 |
| Glibc | 2.43 |
| M4 | 1.4.21 |
| Ncurses | 6.6 |
| Bash | 5.3 |
| Coreutils | 9.10 |
| Binutils (pass 2) | 2.46.0 |
| GCC (pass 2) | 15.2.0 |
| Gettext | 1.0 |
| Bison | 3.8.2 |
| Perl | 5.42.0 |
| Python | 3.14.3 |
| Texinfo | 7.2 |
| Util-linux | 2.41.3 |
| Systemd | 259.1 |
| E2fsprogs | 1.47.3 |
