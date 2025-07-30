# SecureVote - Secure Remote Voting System Development Guide

## Project Overview

SecureVote is a zero-trust, cryptographically verified voting system designed to enable secure remote voting with complete transparency and auditability while preserving voter anonymity.

### Core Requirements
1. Remote voting via any internet-capable device
2. Guaranteed voting eligibility verification
3. Fraud-proof design with cryptographic guarantees
4. Individual anonymity preservation
5. Duplicate vote prevention
6. Complete audit trail

## System Architecture

### Microservices Overview

```
secure-voting-prototype/
├── client/              # React voting app (port 3000)
├── auth-service/        # Identity verification (port 4000)
├── credential-service/  # Anonymous token issuance (port 4001)
├── mixer-service/       # Anonymization layer (port 4002)
├── vote-ledger/         # Immutable storage (port 4003)
├── decryptor/          # Threshold decryption (port 4004)
├── audit-dashboard/    # Public audit interface (port 4005)
├── admin-dashboard/    # Election management (port 4006)
├── docker/             # Container configs
├── .github/            # CI/CD and issue templates
└── docs/               # Documentation
```

### Technology Stack

- **Frontend**: React 18 with Tailwind CSS
- **Backend**: Node.js with Express
- **Database**: MongoDB (prototype) → Blockchain (production)
- **Authentication**: OAuth 2.0 / OpenID Connect
- **Cryptography**: libsodium, OpenSSL, snarkjs
- **Containerization**: Docker & Docker Compose
- **Orchestration**: Kubernetes (production)
- **CI/CD**: GitHub Actions

## Quick Start

### Prerequisites

```bash
# Ensure you have installed:
node --version  # v18+
npm --version   # v9+
docker --version  # v24+
docker compose version  # v2+
```

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/secure-voting-prototype.git
cd secure-voting-prototype

# Run the setup script
chmod +x setup.sh
./setup.sh

# Or manually:
docker compose up --build
```

### Development Workflow

```bash
# Start all services
docker compose up

# Start individual service
docker compose up auth-service

# Rebuild after changes
docker compose build [service-name]

# View logs
docker compose logs -f [service-name]

# Run tests
npm test --prefix ./client
npm test --prefix ./auth-service
```

## Service Development Guide

### 1. Client (Voting Interface)

**Location**: `./client`  
**Port**: 3000  
**Purpose**: User-facing voting application

```javascript
// Key Components:
- VoterAuth.jsx        // Identity verification flow
- BallotForm.jsx       // Vote selection interface
- ReceiptView.jsx      // Cryptographic receipt display
- VerifyVote.jsx       // Public ledger verification

// Environment Variables:
REACT_APP_AUTH_SERVICE_URL=http://localhost:4000
REACT_APP_MIXER_SERVICE_URL=http://localhost:4002
REACT_APP_LEDGER_URL=http://localhost:4003
```

### 2. Auth Service

**Location**: `./auth-service`  
**Port**: 4000  
**Purpose**: Voter identity verification

```javascript
// API Endpoints:
POST /api/verify         // Verify voter eligibility
POST /api/face-match     // Biometric verification
GET  /api/status/:id     // Check verification status

// Mock Implementation:
- Simulates government ID verification
- Face matching returns confidence scores
- Issues temporary auth tokens
```

### 3. Credential Service

**Location**: `./credential-service`  
**Port**: 4001  
**Purpose**: Issue anonymous voting credentials

```javascript
// API Endpoints:
POST /api/credential/issue    // Issue voting credential
POST /api/credential/verify   // Verify credential validity
GET  /api/credential/status   // Check if credential used

// Implementation:
- Blind signatures or zkSNARKs
- One-time use enforcement
- Unlinkable to voter identity
```

### 4. Mixer Service

**Location**: `./mixer-service`  
**Port**: 4002  
**Purpose**: Anonymization layer

```javascript
// API Endpoints:
POST /api/mix/submit     // Submit vote for mixing
GET  /api/mix/status     // Mixing pool status
POST /api/mix/batch      // Process vote batch

// Features:
- Shuffles vote order
- Removes timing correlation
- Implements mixnet protocol
```

### 5. Vote Ledger

**Location**: `./vote-ledger`  
**Port**: 4003  
**Purpose**: Immutable vote storage

```javascript
// API Endpoints:
POST /api/ledger/submit       // Store encrypted vote
GET  /api/ledger/receipt/:id  // Get vote receipt
GET  /api/ledger/merkle       // Get Merkle root
GET  /api/ledger/verify       // Verify vote inclusion

// Storage:
- MongoDB with Merkle tree (prototype)
- Ethereum/Hyperledger (production)
```

### 6. Decryptor Service

**Location**: `./decryptor`  
**Port**: 4004  
**Purpose**: Threshold decryption and tallying

```javascript
// API Endpoints:
POST /api/decrypt/init        // Initialize decryption
POST /api/decrypt/share       // Submit key share
GET  /api/decrypt/results     // Get decrypted results

// Security:
- Requires multiple key holders
- Post-election only
- Shamir secret sharing
```

### 7. Audit Dashboard

**Location**: `./audit-dashboard`  
**Port**: 4005  
**Purpose**: Public verification interface

```javascript
// Features:
- Real-time vote counts
- Receipt verification
- Merkle proof explorer
- Observer access controls
```

### 8. Admin Dashboard

**Location**: `./admin-dashboard`  
**Port**: 4006  
**Purpose**: Election management

```javascript
// Features:
- Create/edit elections
- Set voting parameters
- Export audit reports
- Role-based access
```

## Security Implementation

### Cryptographic Components

```javascript
// Vote Encryption (client-side)
const encryptVote = async (vote, publicKey) => {
  const nonce = crypto.randomBytes(24);
  const encrypted = sodium.crypto_box_easy(
    Buffer.from(JSON.stringify(vote)),
    nonce,
    publicKey,
    privateKey
  );
  return { encrypted, nonce };
};

// Receipt Generation
const generateReceipt = (encryptedVote) => {
  const hash = crypto.createHash('sha256');
  hash.update(encryptedVote);
  return {
    receiptId: hash.digest('hex'),
    timestamp: Date.now(),
    merkleLeaf: computeMerkleLeaf(encryptedVote)
  };
};
```

### Authentication Flow

```javascript
// 1. Identity Verification
const verifyIdentity = async (idData, biometric) => {
  const idCheck = await authService.verifyGovernmentId(idData);
  const faceMatch = await authService.matchBiometric(biometric);
  
  if (idCheck.valid && faceMatch.confidence > 0.95) {
    return authService.issueTemporaryToken();
  }
  throw new Error('Verification failed');
};

// 2. Credential Issuance
const issueVotingCredential = async (authToken) => {
  const eligibility = await checkVoterEligibility(authToken);
  if (eligibility.canVote) {
    return credentialService.issueBlindSignature();
  }
};
```

## Configuration

### Environment Variables

Create `.env` files for each service:

```bash
# Common
NODE_ENV=development
LOG_LEVEL=debug

# Auth Service
AUTH_DB_URL=mongodb://localhost:27017/auth
JWT_SECRET=development-secret
FACE_MATCH_THRESHOLD=0.95

# Credential Service
CREDENTIAL_DB_URL=mongodb://localhost:27017/credentials
BLIND_SIGNATURE_KEY=development-key

# Vote Ledger
LEDGER_DB_URL=mongodb://localhost:27017/ledger
MERKLE_TREE_DEPTH=20
```

### Docker Compose Configuration

```yaml
version: '3.8'
services:
  client:
    build: ./client
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_BASE=http://localhost:4000
    depends_on:
      - auth-service
      
  auth-service:
    build: ./auth-service
    ports:
      - "4000:4000"
    environment:
      - NODE_ENV=development
      - DB_URL=mongodb://mongo:27017/auth
    depends_on:
      - mongo
      
  # ... other services
  
  mongo:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
      
volumes:
  mongo-data:
```

## Testing Strategy

### Unit Tests

```javascript
// Example: Testing vote encryption
describe('Vote Encryption', () => {
  test('should encrypt and decrypt vote correctly', () => {
    const vote = { candidate: 'A', timestamp: Date.now() };
    const { encrypted, nonce } = encryptVote(vote, publicKey);
    const decrypted = decryptVote(encrypted, nonce, privateKey);
    expect(decrypted).toEqual(vote);
  });
});
```

### Integration Tests

```javascript
// Example: Testing full voting flow
describe('End-to-End Voting', () => {
  test('complete voting process', async () => {
    // 1. Verify identity
    const authToken = await authService.verify(mockIdData);
    
    // 2. Get credential
    const credential = await credentialService.issue(authToken);
    
    // 3. Submit vote
    const receipt = await voteService.submit(credential, encryptedVote);
    
    // 4. Verify on ledger
    const verified = await ledgerService.verify(receipt.id);
    expect(verified).toBe(true);
  });
});
```

### E2E Tests (Cypress)

```javascript
describe('Voter Experience', () => {
  it('allows eligible voter to cast ballot', () => {
    cy.visit('/');
    cy.contains('Begin Voting').click();
    
    // Identity verification
    cy.get('[data-testid="id-number"]').type('123456789');
    cy.get('[data-testid="verify-button"]').click();
    
    // Cast vote
    cy.get('[data-testid="candidate-A"]').click();
    cy.get('[data-testid="submit-vote"]').click();
    
    // Verify receipt
    cy.contains('Your vote has been recorded');
    cy.get('[data-testid="receipt-hash"]').should('exist');
  });
});
```

## Development Tasks

### Priority 1 - Core Functionality
- [ ] Implement basic auth service with mock ID verification
- [ ] Create credential issuance with JWT tokens
- [ ] Build voting client with encryption
- [ ] Set up basic ledger with MongoDB
- [ ] Implement receipt generation

### Priority 2 - Security Features
- [ ] Add face matching simulation
- [ ] Implement mixnet basics
- [ ] Add Merkle tree to ledger
- [ ] Create threshold decryption mock
- [ ] Build audit dashboard

### Priority 3 - Production Features
- [ ] Offline voting support
- [ ] Multilingual (ES, FR)
- [ ] Admin dashboard
- [ ] Paper trail export
- [ ] Performance optimization

## Deployment

### Local Development
```bash
docker compose up --build
```

### Staging (Docker Swarm)
```bash
docker stack deploy -c docker-compose.yml voting-app
```

### Production (Kubernetes)
```bash
kubectl apply -f k8s/
kubectl rollout status deployment/voting-app
```

## Security Considerations

1. **Never store**:
   - Private keys in code
   - Voter identities linked to votes
   - Unencrypted ballots

2. **Always verify**:
   - Input sanitization
   - Authentication tokens
   - Cryptographic signatures
   - Certificate chains

3. **Audit everything**:
   - API calls
   - Vote submissions
   - Admin actions
   - System changes

## Troubleshooting

### Common Issues

**Services not connecting**:
```bash
docker compose logs -f [service-name]
# Check network connectivity
docker network ls
```

**Database connection errors**:
```bash
# Ensure MongoDB is running
docker compose ps mongo
# Check connection string in .env
```

**Build failures**:
```bash
# Clear Docker cache
docker system prune -a
# Rebuild from scratch
docker compose build --no-cache
```

## API Documentation

Full API documentation available at:
- Auth Service: http://localhost:4000/api-docs
- Credential Service: http://localhost:4001/api-docs
- Vote Ledger: http://localhost:4003/api-docs

## Contributing

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes with tests
3. Run linting: `npm run lint`
4. Submit PR with description
5. Wait for CI/CD checks

## License

This project is licensed under the MIT License for the open-source components.
Proprietary components are protected under separate commercial license.

## Support

- GitHub Issues: [Report bugs](https://github.com/YOUR_USERNAME/secure-voting-prototype/issues)
- Documentation: [Wiki](https://github.com/YOUR_USERNAME/secure-voting-prototype/wiki)
- Security: security@securevote.com

---

## Claude Code Integration

To begin development with this guide:

1. Navigate to your project directory
2. Run `./setup.sh` to initialize the environment
3. Start implementing features in priority order
4. Use the testing commands after each feature
5. Commit changes with descriptive messages
6. Open GitHub issues for any blockers

Remember to:
- Test each service individually before integration
- Document any API changes
- Keep security considerations in mind
- Follow the established code style


