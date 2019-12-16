#include QMK_KEYBOARD_H


#ifdef RGBLIGHT_ENABLE
//Following line allows macro to read current RGB settings
extern rgblight_config_t rgblight_config;
rgblight_config_t RGB_current_config;
#endif

extern uint8_t is_master;

// Each layer gets a name for readability, which is then used in the keymap matrix below.
// The underscores don't mean anything - you can have a layer called STUFF or any other name.
// Layer names don't all need to be of the same length, obviously, and you can also skip them
// entirely and just use numbers.
enum layer_number {
  _0ANKI,
  _BASE,
  _LOWER,
  _RAISE,
  _ADJUST,
  _5MEDIA,
  _6WOW,
  _7WOWALPHA,
  _8WAYSTN,
  _9PSEUDOLO,
  _10PSEUDOHI,
  _11PSEUDOMEDIA,
};



#define KC_MAC_UNDO LGUI(KC_Z)
#define KC_MAC_CUT LGUI(KC_X)
#define KC_MAC_COPY LGUI(KC_C)
#define KC_MAC_PASTE LGUI(KC_V)
#define KC_PC_UNDO LCTL(KC_Z)
#define KC_PC_CUT LCTL(KC_X)
#define KC_PC_COPY LCTL(KC_C)
#define KC_PC_PASTE LCTL(KC_V)
#define ES_LESS_MAC KC_GRAVE
#define ES_GRTR_MAC LSFT(KC_GRAVE)
#define ES_BSLS_MAC ALGR(KC_6)
#define NO_PIPE_ALT KC_GRAVE
#define NO_BSLS_ALT KC_EQUAL
//Macros
#define M_SAMPLE M(KC_SAMPLEMACRO)

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = { \
[_0ANKI] = LAYOUT_ortho_4x12(
  KC_MAC_UNDO,   KC_1,  KC_2,  KC_3,  KC_4,   KC_AT,  KC_AT,    KC_1,   KC_2,  KC_3,  KC_4,  KC_MAC_UNDO,
  KC_NO,         KC_NO, KC_NO, KC_NO, KC_NO,  KC_NO,    KC_NO,    KC_NO,  KC_NO, KC_NO, KC_NO, KC_NO,
  KC_NO,         KC_NO, KC_NO, KC_NO, KC_NO,  KC_NO,    KC_NO,    KC_NO,  KC_NO, KC_NO, KC_NO, KC_NO,
  TO(1),         KC_NO, KC_NO, KC_NO, MO(9),  KC_SPACE, KC_SPACE, MO(10), KC_NO, KC_NO, KC_NO, KC_NO),
    
  [_BASE] = LAYOUT_ortho_4x12(
    KC_ESCAPE,KC_Q,KC_W,KC_E,KC_R,KC_T,KC_Y,KC_U,KC_I,KC_O,KC_P,KC_BSPACE,
    KC_TAB,KC_A,KC_S,KC_D,KC_F,KC_G,KC_H,KC_J,KC_K,KC_L,KC_SCOLON,KC_ENTER,
    KC_LSHIFT,KC_Z,KC_X,KC_C,KC_V,KC_B,KC_N,KC_M,KC_COMMA,KC_DOT,KC_SLASH,KC_RSHIFT,
    MO(8),KC_LCTRL,KC_LALT,KC_LGUI,MO(2),KC_SPACE,KC_SPACE,MO(3),KC_LEFT,KC_DOWN,KC_UP,KC_RIGHT),

  [_LOWER] = LAYOUT_ortho_4x12(
    KC_TILD,        KC_EXLM,          KC_AT,            KC_HASH,          KC_DLR,           KC_PERC,           KC_CIRC,         KC_AMPR,        KC_ASTR,           KC_LPRN,             KC_RPRN,             LCTL(LGUI(LSFT(KC_4))),
    KC_DELETE,      KC_F1,            KC_F2,            KC_F3,            KC_F4,            KC_F5,             KC_F6,           KC_PLUS,        KC_UNDS,           KC_LCBR,             KC_RCBR,             KC_PIPE,
    KC_TRANSPARENT, LALT(LCTL(KC_D)), LALT(LCTL(KC_F)), LALT(LCTL(KC_G)), KC_F10,           KC_F11,            KC_F12,          KC_NONUS_HASH,  KC_NONUS_BSLASH,   KC_HOME,             KC_END,              KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT,   KC_TRANSPARENT,   KC_TRANSPARENT,   KC_TRANSPARENT,   KC_TRANSPARENT,    KC_TRANSPARENT,  KC_AUDIO_MUTE,  KC_AUDIO_VOL_DOWN, KC_AUDIO_VOL_UP,     KC_MEDIA_PLAY_PAUSE, KC_TRANSPARENT),
    
  [_RAISE] = LAYOUT_ortho_4x12(
    KC_GRAVE,KC_1,KC_2,KC_3,KC_4,KC_5,KC_6,KC_7,KC_8,KC_9,KC_0,LCTL(LGUI(LSFT(KC_4))),
    KC_DELETE,KC_F1,KC_F2,KC_F3,KC_F4,KC_F5,KC_F6,KC_MINUS,KC_EQUAL,KC_LBRACKET,KC_RBRACKET,KC_QUOTE,
    KC_BSLASH,KC_F7,KC_F8,KC_F9,KC_F10,KC_F11,KC_F12,KC_NONUS_HASH,KC_NONUS_BSLASH,KC_PGUP,KC_UP,KC_TRANSPARENT,
    KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_NO,KC_TRANSPARENT,MO(5),KC_LEFT,KC_DOWN,KC_RIGHT),

  [_ADJUST] = LAYOUT_ortho_4x12(
    KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,
    KC_TRANSPARENT,RGB_TOG, RGB_HUI, RGB_SAI, RGB_VAI, AG_NORM,                   AG_SWAP, KC_MINS, KC_EQL,  KC_PSCR, KC_SLCK, RESET,
    KC_TRANSPARENT, RGB_MOD, RGB_HUD, RGB_SAD, RGB_VAD,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,
    TO(1),KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT),

  [_5MEDIA] = LAYOUT_ortho_4x12(KC_TRANSPARENT,KC_MEDIA_PREV_TRACK,KC_MEDIA_PLAY_PAUSE,KC_MEDIA_NEXT_TRACK,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_AUDIO_MUTE,KC_AUDIO_VOL_DOWN,KC_AUDIO_VOL_UP,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_NO,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT),

  [_6WOW] = LAYOUT_ortho_4x12(LCTL(KC_1),LCTL(KC_2),LCTL(KC_3),LCTL(KC_4),LCTL(KC_5),LCTL(KC_6),LCTL(KC_7),LCTL(KC_8),LCTL(KC_9),LCTL(KC_0),KC_TRANSPARENT,KC_BSPACE,KC_1,KC_2,KC_3,KC_4,KC_5,KC_6,KC_7,KC_8,KC_9,KC_0,KC_GRAVE,KC_ENTER,KC_GRAVE,KC_Q,KC_W,KC_E,KC_TRANSPARENT,KC_B,KC_TRANSPARENT,KC_M,KC_TRANSPARENT,KC_Q,KC_W,KC_E,TO(1),KC_A,KC_S,KC_D,KC_T,KC_SPACE,KC_SPACE,MO(7),KC_T,KC_A,KC_S,KC_D),

  [_7WOWALPHA] = LAYOUT_ortho_4x12(KC_TAB,KC_Q,KC_W,KC_E,KC_R,KC_T,KC_Y,KC_U,KC_I,KC_O,KC_P,KC_BSPACE,KC_ESCAPE,KC_A,KC_S,KC_D,KC_F,KC_G,KC_H,KC_J,KC_K,KC_L,KC_SCOLON,KC_ENTER,KC_LSHIFT,KC_Z,KC_X,KC_C,KC_V,KC_B,KC_N,KC_M,KC_COMMA,KC_DOT,KC_SLASH,KC_RSHIFT,TO(1),KC_LCTRL,KC_LALT,KC_LGUI,KC_TRANSPARENT,KC_SPACE,KC_SPACE,KC_TRANSPARENT,KC_LEFT,KC_DOWN,KC_UP,KC_RIGHT),

  [_8WAYSTN] = LAYOUT_ortho_4x12(
    KC_TRANSPARENT,TO(0),TO(6),TO(4),KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,TO(0),TO(6),KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,
    KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,
    KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,
    KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,LCTL(KC_LEFT),KC_TRANSPARENT,KC_TRANSPARENT,LCTL(KC_RIGHT)),

  [_9PSEUDOLO] = LAYOUT_ortho_4x12(
    RESET,KC_EXLM,KC_AT,KC_HASH,KC_DLR,KC_PERC,KC_CIRC,KC_AMPR,KC_ASTR,KC_LPRN,
    KC_RPRN,LCTL(LGUI(LSFT(KC_4))),KC_DELETE,KC_F1,KC_F2,KC_F3,KC_F4,KC_F5,KC_F6,KC_PLUS,KC_UNDS,KC_LCBR,KC_RCBR,KC_PIPE,KC_TRANSPARENT,LALT(LCTL(KC_D)),LALT(LCTL(KC_F)),LALT(LCTL(KC_G)),KC_F10,KC_F11,KC_F12,KC_NONUS_HASH,KC_NONUS_BSLASH,KC_HOME,KC_END,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_NO,KC_TRANSPARENT,KC_AUDIO_MUTE,KC_AUDIO_VOL_DOWN,KC_AUDIO_VOL_UP,KC_MEDIA_PLAY_PAUSE),

  [_10PSEUDOHI] = LAYOUT_ortho_4x12(KC_GRAVE,KC_1,KC_2,KC_3,KC_4,KC_5,KC_6,KC_7,KC_8,KC_9,KC_0,LCTL(LGUI(LSFT(KC_4))),KC_DELETE,KC_F1,KC_F2,KC_F3,KC_F4,KC_F5,KC_F6,KC_MINUS,KC_EQUAL,KC_LBRACKET,KC_RBRACKET,KC_QUOTE,KC_BSLASH,KC_F7,KC_F8,KC_F9,KC_F10,KC_F11,KC_F12,KC_NONUS_HASH,KC_NONUS_BSLASH,KC_PGUP,KC_UP,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_NO,KC_TRANSPARENT,MO(11),KC_LEFT,KC_DOWN,KC_RIGHT),
  
  [_11PSEUDOMEDIA] = LAYOUT_ortho_4x12(KC_TRANSPARENT,KC_MEDIA_PREV_TRACK,KC_MEDIA_PLAY_PAUSE,KC_MEDIA_NEXT_TRACK,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_AUDIO_MUTE,KC_AUDIO_VOL_DOWN,KC_AUDIO_VOL_UP,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_NO,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT,KC_TRANSPARENT),

};

// define variables for reactive RGB
bool TOG_STATUS = false;  


uint32_t layer_state_set_user(uint32_t state) {
    switch (biton32(state)) {
    case (0):
        rgblight_mode_noeeprom(1);
        rgblight_setrgb(0,0,0);
        rgblight_setrgb_at(51,255,255,0);
        rgblight_setrgb_at(51,255,255,5);
        rgblight_setrgb_at(255,181,51,1);
        rgblight_setrgb_at(255,181,51,2);
        rgblight_setrgb_at(255,181,51,3);
        rgblight_setrgb_at(255,181,51,4);
        rgblight_sethsv_at(30, 140, 40, 18);
      

        break;
    case (2):
        rgblight_mode_noeeprom(1);
        rgblight_setrgb(255,181,51);  

         rgblight_sethsv_range(30, 220, 120, 18, 24);

        break;
    case (3):
        rgblight_mode_noeeprom(1);
        rgblight_setrgb(255,181,51);  

         rgblight_sethsv_range(30, 220, 160, 18, 24);
        break;
    case (4):
    
        rgblight_mode_noeeprom(17);

        break;
    case (6):
        rgblight_mode_noeeprom(16);

        break;
    case (7):
        rgblight_mode_noeeprom(1);
        rgblight_sethsv   (130, 200, 90);
        break;
    case (8):
        rgblight_mode_noeeprom(1);
        rgblight_sethsv   (100,225,90);
        break;
    default: // for any other layers, or the default layer
        rgblight_mode_noeeprom(1);
        rgblight_setrgb(255,181,51);  

         rgblight_sethsv_range(30, 220, 160, 18, 24);
        // rgblight_setrgb_at(255,75,0,18);
              
        break;
    }
  return state;
};

// Setting ADJUST layer RGB back to default
void update_tri_layer_RGB(uint8_t layer1, uint8_t layer2, uint8_t layer3) {
  if (IS_LAYER_ON(layer1) && IS_LAYER_ON(layer2)) {
    #ifdef RGBLIGHT_ENABLE
      rgblight_mode_noeeprom(RGB_current_config.mode);
    #endif
    layer_on(layer3);
  } else {
    layer_off(layer3);
  }
}

void matrix_init_user(void) {
    #ifdef RGBLIGHT_ENABLE
      rgblight_init();
      RGB_current_config = rgblight_config;
    #endif
}


