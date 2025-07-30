# Vote-Secured.net API Documentation

## API Overview

The Vote-Secured.net platform provides a comprehensive RESTful API for secure voting operations, election management, and audit functions. All API endpoints implement robust security measures including authentication, rate limiting, and comprehensive logging.

## Base Configuration

- **Base URL**: `https://api.vote-secured.net/v1`
- **Protocol**: HTTPS only (TLS 1.3)
- **Format**: JSON
- **Authentication**: JWT tokens with MFA
- **Rate Limiting**: Per-endpoint limits with burst allowance

## Authentication

### Authentication Flow
```
1. Initial Login → 2. MFA Challenge → 3. JWT Token → 4. API Access
```

### Token Structure
```json
{
  "token_type": "Bearer",
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "expires_in": 3600,
  "refresh_token": "rt_abc123...",
  "scope": "vote cast audit"
}
```

### Security Headers
All API requests must include:
```http
Authorization: Bearer <access_token>
X-API-Version: 1.0
X-Request-ID: <unique_request_id>
User-Agent: VoteSecured-Client/1.0
```

## Core API Endpoints

### Authentication Endpoints

#### POST /auth/login
Initiate voter authentication process.

**Request:**
```json
{
  "voter_id": "VS2024-ABC123",
  "password": "secure_password",
  "election_id": "election_2024_general"
}
```

**Response:**
```json
{
  "status": "mfa_required",
  "session_id": "sess_xyz789",
  "mfa_methods": ["sms", "email", "totp"],
  "expires_in": 300
}
```

#### POST /auth/mfa/verify
Complete multi-factor authentication.

**Request:**
```json
{
  "session_id": "sess_xyz789",
  "mfa_method": "sms",
  "verification_code": "123456"
}
```

**Response:**
```json
{
  "status": "authenticated",
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "voter_profile": {
    "voter_id": "VS2024-ABC123",
    "district": "District 5",
    "ballot_style": "BS_2024_D5_001"
  }
}
```

#### POST /auth/refresh
Refresh expired access token.

**Request:**
```json
{
  "refresh_token": "rt_abc123..."
}
```

### Election Management

#### GET /elections
Retrieve available elections for the authenticated voter.

**Response:**
```json
{
  "elections": [
    {
      "election_id": "election_2024_general",
      "name": "2024 General Election",
      "start_time": "2024-11-05T06:00:00Z",
      "end_time": "2024-11-05T20:00:00Z",
      "status": "active",
      "voter_eligible": true,
      "ballot_style": "BS_2024_D5_001"
    }
  ]
}
```

#### GET /elections/{election_id}/ballot
Retrieve ballot for specific election.

**Response:**
```json
{
  "election_id": "election_2024_general",
  "ballot_id": "ballot_2024_d5_001",
  "ballot_style": "BS_2024_D5_001",
  "contests": [
    {
      "contest_id": "president_2024",
      "title": "President of the United States",
      "type": "single_choice",
      "candidates": [
        {
          "candidate_id": "cand_001",
          "name": "Jane Doe",
          "party": "Democratic Party"
        },
        {
          "candidate_id": "cand_002",
          "name": "John Smith",
          "party": "Republican Party"
        }
      ]
    }
  ],
  "ballot_hash": "sha256:abc123...",
  "signature": "sig_def456..."
}
```

### Vote Casting

#### POST /votes/cast
Cast encrypted vote for election.

**Request:**
```json
{
  "election_id": "election_2024_general",
  "ballot_id": "ballot_2024_d5_001",
  "encrypted_ballot": {
    "contests": {
      "president_2024": {
        "encrypted_selection": "enc_abc123...",
        "proof": "zkp_def456...",
        "nonce": "nonce_ghi789..."
      }
    },
    "signature": "voter_sig_jkl012...",
    "timestamp": "2024-11-05T14:30:00Z"
  },
  "verification_code": "VC_2024_xyz789"
}
```

**Response:**
```json
{
  "status": "vote_accepted",
  "vote_id": "vote_2024_mno345",
  "receipt": {
    "receipt_id": "receipt_pqr678",
    "election_id": "election_2024_general",
    "timestamp": "2024-11-05T14:30:15Z",
    "ballot_hash": "sha256:stu901...",
    "verification_hash": "sha256:vwx234...",
    "signature": "system_sig_yza567..."
  },
  "confirmation": {
    "message": "Your vote has been securely recorded",
    "verification_url": "https://verify.vote-secured.net/receipt/receipt_pqr678"
  }
}
```

#### GET /votes/receipt/{receipt_id}
Retrieve vote receipt for verification.

**Response:**
```json
{
  "receipt_id": "receipt_pqr678",
  "election_id": "election_2024_general",
  "voter_id_hash": "sha256:voter_hash...",
  "timestamp": "2024-11-05T14:30:15Z",
  "ballot_hash": "sha256:stu901...",
  "verification_hash": "sha256:vwx234...",
  "signature": "system_sig_yza567...",
  "verification_status": "valid",
  "public_verification_url": "https://verify.vote-secured.net/receipt/receipt_pqr678"
}
```

### Results and Tallying

#### GET /results/{election_id}/preliminary
Get preliminary election results (real-time).

**Response:**
```json
{
  "election_id": "election_2024_general",
  "status": "counting",
  "last_updated": "2024-11-05T20:15:00Z",
  "total_votes_cast": 15847,
  "total_eligible_voters": 22500,
  "turnout_percentage": 70.4,
  "contests": [
    {
      "contest_id": "president_2024",
      "title": "President of the United States",
      "results": [
        {
          "candidate_id": "cand_001",
          "name": "Jane Doe",
          "votes": 8523,
          "percentage": 53.8
        },
        {
          "candidate_id": "cand_002",
          "name": "John Smith",
          "votes": 7324,
          "percentage": 46.2
        }
      ]
    }
  ],
  "verification_proof": "tally_proof_abc123..."
}
```

#### GET /results/{election_id}/final
Get certified final election results.

**Response:**
```json
{
  "election_id": "election_2024_general",
  "status": "certified",
  "certification_date": "2024-11-15T12:00:00Z",
  "certified_by": "Chief Election Officer",
  "total_votes_cast": 16203,
  "contests": [
    {
      "contest_id": "president_2024",
      "title": "President of the United States",
      "winner": {
        "candidate_id": "cand_001",
        "name": "Jane Doe",
        "votes": 8651,
        "percentage": 53.4
      },
      "results": [
        {
          "candidate_id": "cand_001",
          "name": "Jane Doe",
          "votes": 8651,
          "percentage": 53.4
        },
        {
          "candidate_id": "cand_002",
          "name": "John Smith",
          "votes": 7552,
          "percentage": 46.6
        }
      ]
    }
  ],
  "audit_completed": true,
  "certification_signature": "cert_sig_def456..."
}
```

### Audit and Verification

#### GET /audit/trail/{election_id}
Access audit trail for election (requires auditor role).

**Parameters:**
- `start_time` (optional): ISO 8601 timestamp
- `end_time` (optional): ISO 8601 timestamp
- `event_type` (optional): Filter by event type
- `limit` (optional): Number of records (default: 100, max: 1000)

**Response:**
```json
{
  "election_id": "election_2024_general",
  "audit_events": [
    {
      "event_id": "evt_001",
      "timestamp": "2024-11-05T14:30:15Z",
      "event_type": "vote_cast",
      "voter_token_hash": "sha256:voter_abc...",
      "ballot_hash": "sha256:ballot_def...",
      "verification_status": "success",
      "signature": "event_sig_ghi..."
    }
  ],
  "total_events": 16203,
  "page_info": {
    "has_next_page": true,
    "next_cursor": "cursor_jkl789"
  }
}
```

#### POST /audit/verify/batch
Batch verification of multiple votes or events.

**Request:**
```json
{
  "verification_requests": [
    {
      "type": "vote_receipt",
      "receipt_id": "receipt_pqr678"
    },
    {
      "type": "audit_event",
      "event_id": "evt_001"
    }
  ]
}
```

**Response:**
```json
{
  "verification_results": [
    {
      "receipt_id": "receipt_pqr678",
      "status": "valid",
      "verified_at": "2024-11-06T10:15:00Z",
      "signature_valid": true,
      "hash_matches": true
    },
    {
      "event_id": "evt_001",
      "status": "valid",
      "verified_at": "2024-11-06T10:15:01Z",
      "signature_valid": true,
      "hash_matches": true
    }
  ]
}
```

### Administrative Endpoints

#### GET /admin/system/status
Get system health and status (requires admin role).

**Response:**
```json
{
  "system_status": "operational",
  "uptime": "99.99%",
  "active_elections": 1,
  "total_registered_voters": 45000,
  "api_version": "1.0.0",
  "security_status": {
    "tls_certificate_valid": true,
    "security_patches_current": true,
    "intrusion_detection_active": true,
    "audit_logging_enabled": true
  },
  "performance_metrics": {
    "average_response_time_ms": 150,
    "requests_per_second": 500,
    "error_rate_percentage": 0.01
  }
}
```

#### POST /admin/elections/{election_id}/certify
Certify election results (requires election official role).

**Request:**
```json
{
  "certification_notes": "Election conducted without security incidents. All audit requirements satisfied.",
  "auditor_approval": "audit_approval_abc123",
  "certification_signature": "official_sig_def456"
}
```

## WebSocket API

### Real-time Election Updates

#### Connection
```javascript
const ws = new WebSocket('wss://api.vote-secured.net/v1/ws/elections/election_2024_general');
```

#### Message Types
```json
{
  "type": "vote_count_update",
  "data": {
    "contest_id": "president_2024",
    "total_votes": 15847,
    "updated_results": [...],
    "timestamp": "2024-11-05T20:15:00Z"
  }
}
```

## Error Handling

### Error Response Format
```json
{
  "error": {
    "code": "INVALID_BALLOT",
    "message": "The submitted ballot contains invalid selections",
    "details": {
      "contest_id": "president_2024",
      "issue": "Multiple selections for single-choice contest"
    },
    "request_id": "req_abc123",
    "timestamp": "2024-11-05T14:30:00Z"
  }
}
```

### Error Codes
- `AUTHENTICATION_REQUIRED` (401): Valid authentication token required
- `INSUFFICIENT_PRIVILEGES` (403): User lacks required permissions
- `INVALID_BALLOT` (400): Ballot format or content is invalid
- `VOTE_ALREADY_CAST` (409): Voter has already submitted a ballot
- `ELECTION_NOT_ACTIVE` (423): Election is not currently accepting votes
- `RATE_LIMIT_EXCEEDED` (429): Too many requests from client
- `SYSTEM_MAINTENANCE` (503): System temporarily unavailable

## Rate Limiting

### Limits by Endpoint Type
- **Authentication**: 5 requests per minute per IP
- **Vote Casting**: 1 request per election per voter
- **Results**: 60 requests per minute per authenticated user
- **Audit**: 100 requests per minute per auditor

### Rate Limit Headers
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1699123200
Retry-After: 300
```

## SDK Examples

### JavaScript/Node.js
```javascript
const VoteSecuredAPI = require('vote-secured-sdk');

const api = new VoteSecuredAPI({
  baseURL: 'https://api.vote-secured.net/v1',
  apiKey: 'your_api_key'
});

// Cast a vote
const voteResult = await api.votes.cast({
  electionId: 'election_2024_general',
  encryptedBallot: encryptedBallotData
});
```

### Python
```python
import vote_secured

client = vote_secured.Client(
    base_url='https://api.vote-secured.net/v1',
    api_key='your_api_key'
)

# Get election results
results = client.results.get_final('election_2024_general')
```

## Security Considerations

### API Security
- All endpoints require HTTPS (TLS 1.3)
- Authentication tokens expire after 1 hour
- Rate limiting prevents abuse
- Request/response logging for audit
- Input validation on all parameters

### Data Privacy
- Personally identifiable information is hashed
- Vote contents are encrypted end-to-end
- Audit logs use anonymized identifiers
- GDPR compliance for data handling

---

*This API enables secure, transparent, and auditable electronic voting while maintaining the highest standards of privacy and security.*