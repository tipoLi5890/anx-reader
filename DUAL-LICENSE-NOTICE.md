# Dual License Notice - Ollama AI Integration

## Overview

This project contains components that are subject to different licensing terms. While the main Anx Reader project is licensed under the MIT License, specific Ollama AI integration features developed by **Genius Holdings Co., Ltd** are subject to a dual licensing scheme.

## Licensing Structure

### Main Project (Anx Reader)
- **License**: MIT License
- **Copyright**: (c) 2025 Anxcye
- **Coverage**: All components except those specifically mentioned below

### Ollama AI Integration Features
- **License**: Dual License (Commercial + AGPL-3.0)
- **Copyright**: (c) 2025 Genius Holdings Co., Ltd (https://github.com/ezoxygenTeam)
- **Managed by**: tipo (LI, CHING-YU) (https://github.com/tipoLi5890)
- **License File**: [LICENSE-OLLAMA-AI.md](LICENSE-OLLAMA-AI.md)

## Dual Licensed Components

The following components are subject to the dual licensing terms:

### Files
- `lib/service/ai/ollama_client.dart` - Our implementation code
- `lib/page/settings_page/ai.dart` - Ollama-specific portions (our code only)

### Third-Party Assets (NOT dual licensed)
- `assets/images/ollama.png` - Third-party asset not covered by dual licensing

### Git Commits
- `8a8085f2de5acc6adcef51516cace436ef39ad5a` - Initial Ollama integration
- `ec3a075cb1b968b9f644fe1d06767cfd1852cb0e` - Comprehensive Ollama optimizations
- `bbb41a8b976fdec0eddd0e1aca3da3a91118b01b` - Code cleanup for production

### Features
- Complete Ollama AI client implementation
- Dual endpoint support (/api/chat and /api/generate)
- Thinking model integration (DeepSeek-R1)
- Advanced NDJSON streaming processing
- Memory management optimizations
- Specialized UI/UX enhancements

## How to Comply

### For Contributors
When contributing to this project, please be aware of the dual licensing structure:

1. **General contributions** to the main Anx Reader project remain under MIT License
2. **Modifications to Ollama AI features** must comply with the dual licensing terms
3. **New Ollama-related features** may be subject to dual licensing at the discretion of Genius Holdings Co., Ltd

### For Users and Redistributors

#### If using the complete project:
- The main project (MIT License) can be used according to MIT terms
- Ollama AI features require license selection (Commercial or AGPL-3.0)

#### If using only non-Ollama components:
- Standard MIT License terms apply
- No additional restrictions

#### If using or modifying Ollama AI features:
- **Option 1**: Obtain commercial license from Genius Holdings Co., Ltd
- **Option 2**: Comply with AGPL-3.0 terms (including source disclosure for network use)

## License Selection Guide

### Choose Commercial License for Ollama Features:
✅ Proprietary software integration  
✅ Commercial distribution without source disclosure  
✅ Professional support and warranties  
✅ Sublicensing rights  

### Choose AGPL-3.0 for Ollama Features:
✅ Open source projects  
✅ Educational and research use  
✅ Community-driven development  
✅ Compliance with copyleft requirements  

## Technical Integration

The Ollama AI features are designed to be modular and can be:
- **Included**: Full AI functionality with dual license compliance
- **Excluded**: Remove Ollama-specific files for MIT-only distribution
- **Replaced**: Implement alternative AI integrations under MIT terms

## Contact Information

### For Ollama AI Features (Dual Licensed)
**Genius Holdings Co., Ltd**  
**Company GitHub**: https://github.com/ezoxygenTeam  
**Manager**: tipo (LI, CHING-YU)  
**Manager GitHub**: https://github.com/tipoLi5890  
**Purpose**: Commercial licensing, technical support, feature inquiries

### For Main Project (MIT Licensed)
**Anx Reader Project**  
**Copyright Holder**: Anxcye  
**Purpose**: General project questions, MIT-licensed contributions

## Compliance Examples

### Example 1: Open Source Project
If you're building an open source e-book reader and want to include Ollama AI features:
- Choose AGPL-3.0 for Ollama features
- Ensure your entire project complies with AGPL-3.0 copyleft requirements
- Provide source code access for network services

### Example 2: Commercial Application
If you're building a commercial e-book platform:
- Obtain commercial license for Ollama features from Genius Holdings Co., Ltd
- MIT License covers the rest of the project
- No source code disclosure required

### Example 3: Contribution Guidelines
If you want to contribute improvements to Ollama features:
- Contributions will be subject to dual licensing terms
- Copyright may be assigned to Genius Holdings Co., Ltd
- Contact project managers before significant Ollama-related contributions

---

*This dual licensing approach balances open source collaboration with commercial protection, ensuring sustainable development of advanced AI features while maintaining the open nature of the core Anx Reader project.*