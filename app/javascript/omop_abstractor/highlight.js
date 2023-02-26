class Highlight {
  constructor() {
    this.highlightedRanges = [];
  }

  clearAllHighlights() {
    document.querySelectorAll('.abstractor_suggestion').forEach((abstractorSuggestion) => {
      this.removeHighlightsFromSuggestion(abstractorSuggestion, true);
    });
  }

  highlight(abstractorSuggestion) {
    var self, tooltipTarget, target, tab;
    self = this;
    tooltipTarget = abstractorSuggestion.querySelector('.abstractor_abstraction_source_tooltip_img');

    if (tooltipTarget) {
      target = tooltipTarget.attributes['rel'];
      tab = $(target.value).find('.abstractor_source_tab');
      target = tooltipTarget.attributes['rel'];
      tab = $(tab).html().trim();
      $(target.value).find('.sentence').each(function(index) {
        var hashed_sentence, sentence_match_value;
        sentence_match_value = _.unescape($(this).find('.sentence_match_value').html().trim()).replace(/[.^$*+?()[{\\|\]-]/g, '\\$&');
        hashed_sentence = $(this).find('.sentence_match_value .hashed_sentence').html().trim();
        $(this).find('.match_value').each(function(index) {
          var text_elements, that;
          that = this;
          text_elements = $('#' + tab + " .abstractor_source_tab_content ." + hashed_sentence);
          return text_elements.each(function(index) {
            var match, match_value, regex, text_element;
            text_element = $(this);
            match_value = $(that).html().trim().replace(/[-[\]{}()*+?.,\\^$|#]/g, "\\$&").replace(/\s+/g, "\\s*");
            regex = new RegExp(match_value, 'gi');
            while ((match = regex.exec(text_element.get(0).textContent.replace('<','&lt;').replace('>','&gt;'))) !== null) {
              self.highlightedRanges.push(self.highlightRange(text_element.get(0), match.index, match.index + match[0].length, 'yellow'));
            }
          });
        });
      });
    }
  }

  removeHighlightsFromSuggestion(abstractorSuggestion, highlightFirst = false) {
    var  i, is_ie, len, msie, range, sel, serializedRange, ua;
    if (highlightFirst) {
      this.highlight(abstractorSuggestion);
    }
    this.highlightedRanges.forEach((highlightedRange) => {
      this.restoreRange(highlightedRange);
      this.highlightWithColor('white');
    });
    this.highlightedRanges = [];
  }

  getTextNodesIn(node) {
    var children, i, len, textNodes;
    textNodes = [];
    if (node.nodeType === 3) {
      textNodes.push(node);
    } else {
      children = node.childNodes;
      i = 0;
      len = children.length;
      while (i < len) {
        textNodes.push.apply(textNodes, this.getTextNodesIn(children[i]));
        ++i;
      }
    }
    return textNodes;
  }

  setSelectionRange(el, start, end) {
    var charCount, endCharCount, foundStart, i, range, sel, textNode, textNodes, textRange;
    if (document.createRange && window.getSelection) {
      range = document.createRange();
      range.selectNodeContents(el);
      textNodes = this.getTextNodesIn(el);
      foundStart = false;
      charCount = 0;
      endCharCount = void 0;
      i = 0;
      textNode = void 0;
      while (textNode = textNodes[i++]) {
        endCharCount = charCount + textNode.length;
        if (!foundStart && start >= charCount && (start < endCharCount || start === endCharCount && i <= textNodes.length)) {
          range.setStart(textNode, start - charCount);
          foundStart = true;
        }
        if (foundStart && end <= endCharCount) {
          range.setEnd(textNode, end - charCount);
          break;
        }
        charCount = endCharCount;
      }
      sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    } else if (document.selection && document.body.createTextRange) {
      textRange = document.body.createTextRange();
      textRange.moveToElementText(el);
      textRange.collapse(true);
      textRange.moveEnd('character', end);
      textRange.moveStart('character', start);
      textRange.select();
    }
  }

  serializeRange(range) {
    if (!range || range.startContainer === range.endContainer && range.startOffset === range.endOffset) {
      return null;
    } else {
      return {
        startContainer: range.startContainer,
        startOffset: range.startOffset,
        endContainer: range.endContainer,
        endOffset: range.endOffset
      };
    }

  }

  restoreRange(serialized) {
    var range, sel;
    range = document.createRange();
    range.setStart(serialized.startContainer, serialized.startOffset);
    range.setEnd(serialized.endContainer, serialized.endOffset);
    sel = window.getSelection();
    sel.removeAllRanges();
    sel.addRange(range);
  }

  makeEditableAndHighlight(colour) {
    var is_ie, msie, range, sel, serializedRange, ua;

    sel = window.getSelection();
    if (sel.rangeCount && sel.getRangeAt) {
      range = sel.getRangeAt(0);
    }
    ua = window.navigator.userAgent;
    msie = ua.indexOf("MSIE ");
    is_ie = msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./);
    if (is_ie) {
      range.commonAncestorContainer.contentEditable = true;
    } else {
      document.designMode = 'on';
    }
    if (range) {
      sel.removeAllRanges();
      sel.addRange(range);
    }
    if (!document.execCommand('HiliteColor', false, colour)) {
      document.execCommand('BackColor', false, colour);
    }
    serializedRange = this.serializeRange(sel.getRangeAt(0));
    sel.removeAllRanges();
    if (is_ie) {
      range.commonAncestorContainer.contentEditable = false;
    } else {
      document.designMode = 'off';
    }
    return serializedRange;
  }

  highlightWithColor(colour) {
    var range, serializedRange;
    range = void 0;
    serializedRange = void 0;
    if (window.getSelection) {
      serializedRange = this.makeEditableAndHighlight(colour);
    } else if (document.selection && document.selection.createRange) {
      range = document.selection.createRange();
      range.execCommand('BackColor', false, colour);
      serializedRange = this.serializeRange(range);
    }
    return serializedRange;
  }

  highlightRange(el, start, end, color) {
    var serializedRange;
    this.setSelectionRange(el, start, end);
    serializedRange = this.highlightWithColor(color);
    return serializedRange;
  }
}
export default Highlight