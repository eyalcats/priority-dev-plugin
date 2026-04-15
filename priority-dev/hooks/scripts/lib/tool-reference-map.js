// Map (tool_name, tool_input) → required priority-sdk reference filename.
// Returns null for tools we don't care about.

const TRIGGER_SHAPE = /\b(:RETVAL|ERRMSG|WRNMSG|SELECT\s+SQL\.|GOTO\s+\d+|LINK\s+\w+\s+TO)\b/i;

function requiredReferenceFor(toolName, toolInput) {
  toolInput = toolInput || {};

  switch (toolName) {
    case 'websdk_form_action':
      return 'websdk-cookbook.md';

    case 'run_inline_sqli': {
      const mode = (toolInput.mode || 'sqli').toLowerCase();
      return mode === 'dbi' ? 'tables-and-dbi.md' : 'websdk-cookbook.md';
    }

    case 'write_to_editor': {
      const content = String(toolInput.content || '');
      if (toolInput.entityType === 'PROC' || TRIGGER_SHAPE.test(content)) {
        return 'triggers.md';
      }
      return 'forms.md';
    }

    default:
      return null;
  }
}

module.exports = { requiredReferenceFor };
