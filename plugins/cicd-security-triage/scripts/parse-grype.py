#!/usr/bin/env python3
"""
Grype Parser - Normaliza output de Grype a schema report-formats v1.0

Uso:
    python parse-grype.py grype-output.json normalized-report.json
"""

import json
import sys
from datetime import datetime
from typing import Any


SEVERITY_MAP = {
    "Critical": "critical",
    "High": "high",
    "Medium": "medium",
    "Low": "low",
    "Negligible": "info",
    "Unknown": "info",
}


EXPLOITABILITY_MAP = {
    "exploited": "exploited",
    "poc": "poc",
    "theoretical": "theoretical",
    "none": "none",
}


def map_severity(grype_severity: str) -> str:
    return SEVERITY_MAP.get(grype_severity, "info")


def map_exploitability(match: dict) -> str:
    """Grype no tiene exploitability directo, inferimos de metadata"""
    # Buscar en match metadata si hay exploit info
    if "metadata" in match:
        meta = match["metadata"]
        if "exploit" in str(meta).lower():
            return "poc"
    return "theoretical"


def map_exposure(match: dict, target_type: str) -> str:
    """Inferir exposición basado en tipo de target y package"""
    if target_type == "image":
        return "public"  # Container images usually deployed publicly
    pkg = match.get("artifact", {}).get("name", "").lower()
    if any(x in pkg for x in ["test", "dev", "build", "plugin"]):
        return "build-time"
    return "internal"


def extract_cvss(match: dict) -> tuple:
    """Extraer CVSS score y vector de metadata"""
    cvss_score = None
    cvss_vector = None
    if "vulnerability" in match and "cvss" in match["vulnerability"]:
        for cvss in match["vulnerability"]["cvss"]:
            if cvss.get("version", "").startswith("3"):
                cvss_score = cvss.get("score")
                cvss_vector = cvss.get("vector")
                break
    return cvss_score, cvss_vector


def extract_cwe(match: dict) -> list:
    """Extraer CWE IDs"""
    cwes = []
    if "vulnerability" in match and "cwe" in match["vulnerability"]:
        cwes = match["vulnerability"]["cwe"]
    return cwes


def extract_fix(match: dict) -> dict | None:
    """Extraer información de fix disponible"""
    if "vulnerability" in match and "fix" in match["vulnerability"]:
        fix = match["vulnerability"]["fix"]
        return {
            "version": fix.get("version"),
            "type": "upgrade",
            "url": fix.get("url"),
        }
    return None


def parse_grype(input_path: str, output_path: str) -> dict:
    with open(input_path, "r") as f:
        grype_data = json.load(f)

    matches = grype_data.get("matches", [])
    target = grype_data.get("source", {})
    target_type = target.get("type", "directory")
    target_id = target.get("name") or target.get("path") or "unknown"

    findings = []
    severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
    type_counts = {"vulnerability": 0, "secret": 0, "misconfiguration": 0}

    for match in matches:
        vuln = match.get("vulnerability", {})
        artifact = match.get("artifact", {})

        finding_id = vuln.get("id", "")
        if not finding_id:
            continue

        severity = map_severity(vuln.get("severity", "Unknown"))
        cvss_score, cvss_vector = extract_cvss(match)

        finding = {
            "id": finding_id,
            "title": vuln.get("description", finding_id),
            "description": vuln.get("description", ""),
            "severity": severity,
            "cvss_score": cvss_score,
            "cvss_vector": cvss_vector,
            "cwe": extract_cwe(match),
            "location": {
                "dependency": {
                    "name": artifact.get("name", ""),
                    "version": artifact.get("version", ""),
                    "ecosystem": artifact.get("type", "").lower(),
                }
            },
            "exploitability": map_exploitability(match),
            "exposure": map_exposure(match, target_type),
            "fix_available": extract_fix(match),
            "references": vuln.get("urls", []),
            "tags": vuln.get("tags", []),
        }

        findings.append(finding)
        severity_counts[severity] += 1
        type_counts["vulnerability"] += 1

    # Secrets detection (Grype puede detectar secrets)
    secrets = grype_data.get("secrets", [])
    for secret in secrets:
        finding = {
            "id": f"secret-{secret.get('ruleID', 'unknown')}",
            "title": f"Secret detected: {secret.get('ruleID', 'unknown')}",
            "description": secret.get("description", ""),
            "severity": "critical",
            "location": {
                "file": secret.get("file", ""),
                "line": secret.get("line", 0),
            },
            "exploitability": "exploited",
            "exposure": "internal",
            "references": [],
            "tags": ["secret"],
        }
        findings.append(finding)
        severity_counts["critical"] += 1
        type_counts["secret"] += 1

    normalized = {
        "schema_version": "1.0",
        "source": "grype",
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "scan_target": {
            "type": target_type,
            "identifier": target_id,
        },
        "findings": findings,
        "summary": {
            "total": len(findings),
            "by_severity": severity_counts,
            "by_type": type_counts,
        },
    }

    with open(output_path, "w") as f:
        json.dump(normalized, f, indent=2)

    return normalized


def main():
    if len(sys.argv) != 3:
        print("Usage: parse-grype.py <input.json> <output.json>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    try:
        result = parse_grype(input_path, output_path)
        print(f"✅ Parsed {result['summary']['total']} findings from Grype")
        print(f"   Critical: {result['summary']['by_severity']['critical']}")
        print(f"   High: {result['summary']['by_severity']['high']}")
        print(f"   Medium: {result['summary']['by_severity']['medium']}")
        print(f"   Low: {result['summary']['by_severity']['low']}")
        print(f"   Info: {result['summary']['by_severity']['info']}")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()