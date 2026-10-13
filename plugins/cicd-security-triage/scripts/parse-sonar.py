#!/usr/bin/env python3
"""
SonarQube Parser - Normaliza issues + hotspots de SonarQube a schema report-formats v1.0

Uso:
    python parse-sonar.py sonar-issues.json sonar-hotspots.json normalized-report.json
"""

import json
import sys
from datetime import datetime
from typing import Any


SEVERITY_MAP = {
    "BLOCKER": "critical",
    "CRITICAL": "critical",
    "MAJOR": "high",
    "MINOR": "medium",
    "INFO": "low",
}


TYPE_MAP = {
    "VULNERABILITY": "vulnerability",
    "BUG": "vulnerability",
    "CODE_SMELL": "misconfiguration",
    "SECURITY_HOTSPOT": "vulnerability",
}


EXPLOITABILITY_MAP = {
    "VULNERABILITY": "theoretical",
    "BUG": "theoretical",
    "CODE_SMELL": "none",
    "SECURITY_HOTSPOT": "poc",
}


EXPOSURE_MAP = {
    "VULNERABILITY": "public",
    "BUG": "internal",
    "CODE_SMELL": "build-time",
    "SECURITY_HOTSPOT": "internal",
}


def map_severity(sonar_severity: str) -> str:
    return SEVERITY_MAP.get(sonar_severity.upper(), "info")


def map_type(sonar_type: str) -> str:
    return TYPE_MAP.get(sonar_type.upper(), "misconfiguration")


def map_exploitability(sonar_type: str) -> str:
    return EXPLOITABILITY_MAP.get(sonar_type.upper(), "theoretical")


def map_exposure(sonar_type: str) -> str:
    return EXPOSURE_MAP.get(sonar_type.upper(), "internal")


def parse_issues(issues_data: dict) -> list:
    findings = []
    issues = issues_data.get("issues", [])

    for issue in issues:
        severity = map_severity(issue.get("severity", "INFO"))
        issue_type = map_type(issue.get("type", "CODE_SMELL"))

        finding = {
            "id": issue.get("key", ""),
            "title": issue.get("message", issue.get("rule", "")),
            "description": issue.get("message", ""),
            "severity": severity,
            "cwe": [issue.get("cwe", "")] if issue.get("cwe") else [],
            "location": {
                "file": issue.get("component", "").replace(":", "/"),
                "line": issue.get("line", 0),
            },
            "exploitability": map_exploitability(issue.get("type", "CODE_SMELL")),
            "exposure": map_exposure(issue.get("type", "CODE_SMELL")),
            "fix_available": {
                "type": "patch",
                "url": f"https://rules.sonarsource.com/{issue.get('rule', '').lower()}",
            } if issue.get("rule") else None,
            "references": [
                f"https://rules.sonarsource.com/{issue.get('rule', '').lower()}"
            ] if issue.get("rule") else [],
            "tags": [issue.get("type", "").lower()],
        }
        findings.append(finding)

    return findings


def parse_hotspots(hotspots_data: dict) -> list:
    findings = []
    hotspots = hotspots_data.get("hotspots", [])

    for hotspot in hotspots:
        finding = {
            "id": f"hotspot-{hotspot.get('key', '')}",
            "title": f"Security Hotspot: {hotspot.get('ruleKey', 'unknown')}",
            "description": hotspot.get("message", ""),
            "severity": "medium",  # Hotspots son review needed, no vulns confirmadas
            "location": {
                "file": hotspot.get("component", "").replace(":", "/"),
                "line": hotspot.get("line", 0),
            },
            "exploitability": "poc",
            "exposure": "internal",
            "fix_available": {
                "type": "review",
                "url": f"https://rules.sonarsource.com/{hotspot.get('ruleKey', '').lower()}",
            },
            "references": [
                f"https://rules.sonarsource.com/{hotspot.get('ruleKey', '').lower()}"
            ],
            "tags": ["hotspot", "review-needed"],
        }
        findings.append(finding)

    return findings


def parse_sonar(issues_path: str, hotspots_path: str, output_path: str) -> dict:
    # Parse issues
    with open(issues_path, "r") as f:
        issues_data = json.load(f)

    # Parse hotspots (optional)
    hotspots_data = {}
    if hotspots_path:
        with open(hotspots_path, "r") as f:
            hotspots_data = json.load(f)

    project_key = issues_data.get("projectKey") or issues_data.get("project", "unknown")
    findings = []

    findings.extend(parse_issues(issues_data))
    findings.extend(parse_hotspots(hotspots_data))

    severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
    type_counts = {"vulnerability": 0, "secret": 0, "misconfiguration": 0}

    for finding in findings:
        severity_counts[finding["severity"]] += 1
        ftype = finding.get("tags", [""])[0] if finding.get("tags") else "misconfiguration"
        if ftype in type_counts:
            type_counts[ftype] += 1
        else:
            type_counts["misconfiguration"] += 1

    normalized = {
        "schema_version": "1.0",
        "source": "sonarqube",
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "scan_target": {
            "type": "directory",
            "identifier": project_key,
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
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: parse-sonar.py <issues.json> <hotspots.json> <output.json>")
        print("       parse-sonar.py <issues.json> <output.json>  (hotspots optional)")
        sys.exit(1)

    issues_path = sys.argv[1]
    output_path = sys.argv[-1]
    hotspots_path = sys.argv[2] if len(sys.argv) == 4 else None

    try:
        result = parse_sonar(issues_path, hotspots_path, output_path)
        print(f"✅ Parsed {result['summary']['total']} findings from SonarQube")
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