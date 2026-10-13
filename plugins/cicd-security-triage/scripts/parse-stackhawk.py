#!/usr/bin/env python3
"""
StackHawk Parser - Normaliza output de StackHawk a schema report-formats v1.0

Uso:
    python parse-stackhawk.py stackhawk-report.json normalized-report.json
"""

import json
import sys
from datetime import datetime
from typing import Any


SEVERITY_MAP = {
    "CRITICAL": "critical",
    "HIGH": "high",
    "MEDIUM": "medium",
    "LOW": "low",
    "INFO": "info",
}


CWE_MAP = {
    "SQL_INJECTION": "CWE-89",
    "XSS": "CWE-79",
    "PATH_TRAVERSAL": "CWE-22",
    "COMMAND_INJECTION": "CWE-78",
    "LDAP_INJECTION": "CWE-90",
    "XPATH_INJECTION": "CWE-643",
    "XXE": "CWE-611",
    "SSRF": "CWE-918",
    "OPEN_REDIRECT": "CWE-601",
    "CSRF": "CWE-352",
    "BROKEN_AUTH": "CWE-287",
    "BROKEN_ACCESS_CONTROL": "CWE-284",
    "SENSITIVE_DATA_EXPOSURE": "CWE-312",
    "INSECURE_DESERIALIZATION": "CWE-502",
    "USING_COMPONENTS_WITH_KNOWN_VULNS": "CWE-1104",
    "INSUFFICIENT_LOGGING": "CWE-778",
}


def map_severity(hawk_severity: str) -> str:
    return SEVERITY_MAP.get(hawk_severity.upper(), "info")


def map_cwe(plugin_name: str) -> list:
    """Mapear plugin/rule name a CWE"""
    plugin_upper = plugin_name.upper()
    for key, cwe in CWE_MAP.items():
        if key in plugin_upper:
            return [cwe]
    return []


def map_exploitability(finding: dict) -> str:
    """Inferir exploitability de StackHawk finding"""
    # StackHawk findings son vulnerabilidades confirmadas en runtime
    confidence = finding.get("confidence", "").upper()
    if confidence == "HIGH":
        return "exploited"
    elif confidence == "MEDIUM":
        return "poc"
    return "theoretical"


def map_exposure(finding: dict) -> str:
    """Inferir exposición - StackHawk escanea apps running"""
    return "public"


def parse_stackhawk(input_path: str, output_path: str) -> dict:
    with open(input_path, "r") as f:
        hawk_data = json.load(f)

    # StackHawk format: { "findings": [...], "scan": {...} }
    findings_raw = hawk_data.get("findings", [])
    scan_info = hawk_data.get("scan", {})
    app_id = scan_info.get("applicationId", "unknown")
    env = scan_info.get("environment", "unknown")

    findings = []
    severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
    type_counts = {"vulnerability": 0, "secret": 0, "misconfiguration": 0}

    for finding in findings_raw:
        severity = map_severity(finding.get("severity", "INFO"))
        plugin = finding.get("plugin", "")

        normalized_finding = {
            "id": finding.get("findingId", ""),
            "title": finding.get("title", plugin),
            "description": finding.get("description", ""),
            "severity": severity,
            "cvss_score": finding.get("cvssScore"),
            "cvss_vector": finding.get("cvssVector"),
            "cwe": map_cwe(plugin),
            "location": {
                "file": finding.get("file", ""),
                "line": finding.get("line", 0),
            },
            "exploitability": map_exploitability(finding),
            "exposure": map_exposure(finding),
            "fix_available": {
                "type": "code-fix",
                "url": finding.get("references", [None])[0],
            } if finding.get("references") else None,
            "references": finding.get("references", []),
            "tags": [plugin.lower(), "dast"],
        }

        findings.append(normalized_finding)
        severity_counts[severity] += 1
        type_counts["vulnerability"] += 1

    normalized = {
        "schema_version": "1.0",
        "source": "stackhawk",
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "scan_target": {
            "type": "url",
            "identifier": f"{app_id}:{env}",
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
        print("Usage: parse-stackhawk.py <input.json> <output.json>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    try:
        result = parse_stackhawk(input_path, output_path)
        print(f"✅ Parsed {result['summary']['total']} findings from StackHawk")
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