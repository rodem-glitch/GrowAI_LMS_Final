Pre-requisites before installation
Node.js version 20 or higher
macOS, Linux, or Windows
Quick Install
Run instantly with npx
# Using npx (no installation required)
npx @google/gemini-cli
Install globally with npm
npm install -g @google/gemini-cli
Install globally with Homebrew (macOS/Linux)
brew install gemini-cli
Install globally with MacPorts (macOS)
sudo port install gemini-cli
Install with Anaconda (for restricted environments)
# Create and activate a new environment
conda create -y -n gemini_env -c conda-forge nodejs
conda activate gemini_env

# Install Gemini CLI globally via npm (inside the environment)
npm install -g @google/gemini-cli
Release Cadence and Tags
See Releases for more details.

Preview
New preview releases will be published each week at UTC 2359 on Tuesdays. These releases will not have been fully vetted and may contain regressions or other outstanding issues. Please help us test and install with preview tag.

npm install -g @google/gemini-cli@preview
Stable
New stable releases will be published each week at UTC 2000 on Tuesdays, this will be the full promotion of last week's preview release + any bug fixes and validations. Use latest tag.
npm install -g @google/gemini-cli@latest
Nightly
New releases will be published each day at UTC 0000. This will be all changes from the main branch as represented at time of release. It should be assumed there are pending validations and issues. Use nightly tag.
npm install -g @google/gemini-cli@nightly
