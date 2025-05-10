# 🏥 Vickrey Fairness Deal – Subastas Transparentes en Blockchain para el Sector Salud

[![Ethereum](https://img.shields.io/badge/network-Ethereum%20Testnet-yellow)](https://sepolia.etherscan.io)

## 📋 Descripción

Este proyecto implementa un sistema de subasta **Vickrey (segundo precio)** sobre la blockchain de Ethereum, orientado a la **compra segura y justa de medicamentos** por parte de entidades públicas sanitarias. Está desarrollado como parte de la consultoría de aseguramiento de la información para INSEGUS.

El contrato permite:
- Pujas ciegas con compromiso y revelación
- Penalización económica por incumplimiento
- Transparencia y trazabilidad total
- Inicialización infinita de subastas con distintos parámetros

## ⚙️ Características principales

- ✉️ Subastas confidenciales tipo Vickrey (blind auction + reveal)
- ✅ Validación estricta de fechas, valores y participantes
- 🔐 Depósitos del 10% como garantía (con devolución automática)
- 👨‍⚕️ Transparencia y acceso público a resultados al finalizar
- 🔄 Soporte para múltiples subastas concurrentes

## 🚀 Despliegue en Testnet

Este contrato se puede desplegar fácilmente en **Ethereum Sepolia** mediante Remix o Hardhat.

### ➤ Requisitos

- [Metamask](https://metamask.io/) configurado para Sepolia
- [Remix IDE](https://remix.ethereum.org/) o entorno local con Hardhat
- ETH de prueba desde un [Faucet de Sepolia](https://sepoliafaucet.com/)

### ➤ Despliegue rápido en Remix

1. Copia el archivo `VickreyAuction.sol` en Remix.
2. Compila con el compilador Solidity 0.8.x.
3. Conecta Metamask usando `Injected Web3`.
4. Despliega el contrato, inicializa subastas y prueba funciones.

## 🧪 Testing

Se incluye un **plan de pruebas funcional** para asegurar el correcto funcionamiento de:

- Creación de subastas
- Compromiso y revelación de pujas
- Finalización con selección de ganador
- Devolución o retención de depósitos
- Control de errores y condiciones inválidas

> 🔎 Además, se realiza **análisis estático de seguridad** con herramientas como Slither y MythX.  
> Consulta `audit_report/` para los resultados del análisis.

## 📂 Estructura del repositorio

vickrey-fairness-deal/
├── contracts/
│ └── VickreyAuction.sol # Smart contract principal
├── test/
│ └── test_vickrey.js # Pruebas automatizadas 
├── audit_report/
│ └── slither-report.md # Resultados de análisis de seguridad
├── README.md # Este archivo
