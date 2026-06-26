"""
AgriSmartAI :: PostgreSQL database layer (FastAPI backend).
Flutter connects via REST — not directly to PostgreSQL.
"""

from __future__ import annotations

import hashlib
import os
import secrets
from contextlib import contextmanager
from typing import Any, Generator, Optional

import psycopg2
import psycopg2.extras

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/agrismartai",
)


def is_configured() -> bool:
    return bool(DATABASE_URL and "postgresql" in DATABASE_URL)


def check_connection() -> bool:
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        return True
    except Exception:
        return False


@contextmanager
def get_conn() -> Generator[Any, None, None]:
    conn = psycopg2.connect(DATABASE_URL)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt.encode("utf-8"), 120_000
    )
    return f"pbkdf2${salt}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        scheme, salt, digest = stored.split("$", 2)
        if scheme != "pbkdf2":
            return False
        check = hashlib.pbkdf2_hmac(
            "sha256", password.encode("utf-8"), salt.encode("utf-8"), 120_000
        )
        return secrets.compare_digest(check.hex(), digest)
    except Exception:
        return False


def _row_to_user(row: dict) -> dict:
    return {
        "id": str(row["id"]),
        "full_name": row["name"],
        "name": row["name"],
        "email": row["email"],
        "role": row["role"],
        "barangay": row.get("barangay") or "New Bataan",
        "municipality": "New Bataan",
        "province": "Davao de Oro",
    }


def register_user(
    name: str, email: str, password: str, barangay: str = "New Bataan"
) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO users (name, email, password_hash, role, barangay)
                VALUES (%s, %s, %s, 'farmer', %s)
                RETURNING id, name, email, role, barangay, created_at
                """,
                (name, email.lower().strip(), hash_password(password), barangay),
            )
            row = cur.fetchone()
            return _row_to_user(row)


def login_user(email: str, password: str) -> Optional[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT * FROM users WHERE email = %s LIMIT 1",
                (email.lower().strip(),),
            )
            row = cur.fetchone()
            if not row or not verify_password(password, row["password_hash"]):
                return None
            cur.execute(
                "UPDATE users SET last_login = NOW() WHERE id = %s",
                (row["id"],),
            )
            return _row_to_user(row)


def get_user(user_id: str) -> Optional[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
            row = cur.fetchone()
            return _row_to_user(row) if row else None


def create_report(
    user_id: str,
    disease_code: str,
    disease_label: str,
    confidence: float,
    barangay: str = "New Bataan",
    location: str | None = None,
    image_url: str | None = None,
) -> str:
    severity = "moderate"
    if disease_code in ("rice_blast", "tungro"):
        severity = "severe"
    elif disease_code == "healthy":
        severity = "mild"

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO reports
                  (user_id, disease_label, disease_code, confidence_score,
                   severity, status, location, barangay, image_url)
                VALUES (%s, %s, %s, %s, %s, 'pending', %s, %s, %s)
                RETURNING id
                """,
                (
                    user_id,
                    disease_label,
                    disease_code,
                    confidence,
                    severity,
                    location,
                    barangay,
                    image_url,
                ),
            )
            return str(cur.fetchone()[0])


def fetch_reports(user_id: str | None = None) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if user_id:
                cur.execute(
                    """
                    SELECT r.*, u.name AS farmer_name, u.email AS farmer_email
                    FROM reports r
                    JOIN users u ON u.id = r.user_id
                    WHERE r.user_id = %s
                    ORDER BY r.created_at DESC
                    """,
                    (user_id,),
                )
            else:
                cur.execute(
                    """
                    SELECT r.*, u.name AS farmer_name, u.email AS farmer_email
                    FROM reports r
                    JOIN users u ON u.id = r.user_id
                    ORDER BY r.created_at DESC
                    LIMIT 200
                    """
                )
            return [dict(row) for row in cur.fetchall()]


def update_report_status(
    report_id: str, status: str, reviewer_note: str | None = None
) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            if reviewer_note is not None:
                cur.execute(
                    """
                    UPDATE reports
                    SET status = %s, reviewer_note = %s
                    WHERE id = %s
                    """,
                    (status, reviewer_note, report_id),
                )
            else:
                cur.execute(
                    "UPDATE reports SET status = %s WHERE id = %s",
                    (status, report_id),
                )
            return cur.rowcount > 0


def fetch_farmers() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT u.id, u.name, u.email, u.barangay, u.created_at,
                       COUNT(r.id) AS total_scans,
                       SUM(CASE WHEN r.disease_code != 'healthy' THEN 1 ELSE 0 END) AS diseased_scans
                FROM users u
                LEFT JOIN reports r ON r.user_id = u.id
                WHERE u.role = 'farmer'
                GROUP BY u.id
                ORDER BY u.created_at DESC
                """
            )
            return [dict(row) for row in cur.fetchall()]


def fetch_feedback() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT f.id, f.rating, f.comment, f.created_at,
                       u.name AS farmer_name
                FROM feedback f
                JOIN users u ON u.id = f.user_id
                ORDER BY f.created_at DESC
                LIMIT 100
                """
            )
            return [dict(row) for row in cur.fetchall()]


def disease_stats() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT disease_code, disease_label,
                       COUNT(*) AS total_scans,
                       AVG(confidence_score) AS avg_confidence
                FROM reports
                GROUP BY disease_code, disease_label
                ORDER BY total_scans DESC
                """
            )
            return [dict(row) for row in cur.fetchall()]


def delete_report(report_id: str, user_id: str) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM reports WHERE id = %s AND user_id = %s",
                (report_id, user_id),
            )
            return cur.rowcount > 0


def fetch_chatbot_qa() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT question, answer, keywords FROM chatbot_qa")
            return [dict(r) for r in cur.fetchall()]


def dashboard_stats() -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT COUNT(*) AS total FROM users WHERE role = 'farmer'")
            farmers = cur.fetchone()["total"]
            cur.execute("SELECT COUNT(*) AS total FROM reports")
            scans = cur.fetchone()["total"]
            cur.execute(
                "SELECT COUNT(*) AS total FROM reports WHERE status = 'pending'"
            )
            pending = cur.fetchone()["total"]
            cur.execute(
                "SELECT COUNT(*) AS total FROM reports WHERE status = 'verified'"
            )
            verified = cur.fetchone()["total"]
            cur.execute(
                """
                SELECT disease_label, COUNT(*) AS cnt
                FROM reports GROUP BY disease_label ORDER BY cnt DESC LIMIT 5
                """
            )
            by_disease = [
                {"label": r["disease_label"], "count": r["cnt"]}
                for r in cur.fetchall()
            ]
            return {
                "farmers": farmers,
                "scans": scans,
                "pending": pending,
                "verified": verified,
                "by_disease": by_disease,
            }


def seed_admin() -> None:
    """Create default admin if not exists."""
    email = "admin@agrismartai.ph"
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cur.fetchone():
                return
            cur.execute(
                """
                INSERT INTO users (name, email, password_hash, role, barangay)
                VALUES (%s, %s, %s, 'admin', 'New Bataan')
                RETURNING id
                """,
                ("AgriSmart Admin", email, hash_password("admin123")),
            )
            admin_id = cur.fetchone()["id"]
            cur.execute(
                "INSERT INTO admins (user_id, role) VALUES (%s, 'admin')",
                (admin_id,),
            )
