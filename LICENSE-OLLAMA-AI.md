# Dual License for Ollama AI Integration Features

This document applies to the Ollama AI integration features developed by Genius Holdings Co., Ltd, specifically including but not limited to the following commits and their associated code:

- `8a8085f2de5acc6adcef51516cace436ef39ad5a` - feat: add local AI server support with Ollama integration
- `ec3a075cb1b968b9f644fe1d06767cfd1852cb0e` - feat: enhance Ollama AI client with comprehensive optimization and UI improvements  
- `bbb41a8b976fdec0eddd0e1aca3da3a91118b01b` - cleanup: remove debug print statements from ai_client.dart

## Affected Files and Components

### Core Ollama AI Implementation
- `lib/service/ai/ollama_client.dart` - Complete Ollama AI client implementation
- `lib/page/settings_page/ai.dart` - Ollama-specific UI configurations and enhancements

### Third-Party Assets (NOT covered by this license)
- `assets/images/ollama.png` - Third-party asset not covered by dual licensing

### Features Covered
- Dual endpoint support (/api/chat and /api/generate)
- Thinking model support (DeepSeek-R1 integration)
- NDJSON streaming processing optimizations
- Memory management (keep_alive parameter)
- Advanced error handling and timeout management
- Comprehensive UI/UX improvements for Ollama configuration

---

## DUAL LICENSING OPTIONS

You may choose to use the Ollama AI integration features under one of the following two licenses:

### Option 1: Commercial License

**Copyright (c) 2025 Genius Holdings Co., Ltd (https://github.com/ezoxygenTeam)**
**Managed by: tipo (LI, CHING-YU) (https://github.com/tipoLi5890)**

#### Commercial License Terms

Permission is hereby granted to any person or organization obtaining a valid commercial license from Genius Holdings Co., Ltd to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Ollama AI integration features, subject to the following conditions:

1. **Commercial License Required**: Any commercial use, including but not limited to incorporation into proprietary software, SaaS platforms, or commercial applications, requires a separate commercial license agreement with Genius Holdings Co., Ltd.

2. **Attribution**: All copies or substantial portions of the Ollama AI features must include the following copyright notice:
   ```
   Ollama AI Integration Features
   Copyright (c) 2025 Genius Holdings Co., Ltd
   Managed by: tipo (LI, CHING-YU)
   Licensed under Commercial License
   ```

3. **Support and Updates**: Commercial license holders are entitled to technical support and updates as specified in their commercial license agreement.

4. **Liability**: Commercial licenses include warranty and liability terms as specified in the commercial license agreement.

**To obtain a commercial license, please contact:** tipo (LI, CHING-YU) at https://github.com/tipoLi5890

---

### Option 2: GNU Affero General Public License v3.0 (AGPL-3.0)

**Copyright (c) 2025 Genius Holdings Co., Ltd (https://github.com/ezoxygenTeam)**
**Managed by: tipo (LI, CHING-YU) (https://github.com/tipoLi5890)**

#### AGPL-3.0 License Terms

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see https://www.gnu.org/licenses/.

#### Additional AGPL-3.0 Requirements

1. **Network Use Disclosure**: If you run a modified version of this software on a server and let other users communicate with it, you must make the source code available to those users.

2. **Attribution Requirements**: You must retain all copyright notices and include the following attribution in any distribution:
   ```
   Ollama AI Integration Features
   Copyright (c) 2025 Genius Holdings Co., Ltd
   Managed by: tipo (LI, CHING-YU)
   Licensed under AGPL-3.0
   ```

3. **Source Code Availability**: Any modifications or derivative works must be made available under the same AGPL-3.0 license.

4. **Patent Grant**: This license includes an express patent grant from Genius Holdings Co., Ltd for the specific Ollama AI integration features.

---

## License Selection Guide

### Choose Commercial License If:
- You want to integrate the Ollama AI features into proprietary software
- You need to distribute without source code disclosure
- You require commercial support and warranties
- You want to sublicense or sell derivative works

### Choose AGPL-3.0 If:
- You are developing open source software
- You agree to share your modifications under AGPL-3.0
- You want to use the features for educational or research purposes
- You are comfortable with the network use disclosure requirements

---

## Enforcement and Contact

For license clarification, commercial licensing inquiries, or enforcement matters, please contact:

**Genius Holdings Co., Ltd**  
**Company GitHub: https://github.com/ezoxygenTeam**  
**Project Manager: tipo (LI, CHING-YU)**  
**Manager GitHub: https://github.com/tipoLi5890**

---

## Full License Texts

The complete text of the AGPL-3.0 license can be found at: https://www.gnu.org/licenses/agpl-3.0.html

Commercial license terms are provided separately upon request and execution of a commercial license agreement.

---

*This dual licensing approach ensures that the Ollama AI integration features remain available to the open source community while protecting the commercial interests of Genius Holdings Co., Ltd.*