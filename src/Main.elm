port module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Color.Convert exposing (colorToHex)

import Palette exposing (
  Palette, PaletteMsg, SerializedPalette, paletteUl,
  updatePalette, deserializePalette, serializePalette,
  arePaletteEditsValid
  )
import Matrix exposing (matrixDiv)

type Message =
  PaletteMessage PaletteMsg
  | LoadPalette SerializedPalette
  | StartEditing
  | FinishEditing
  | CancelEditing
  | SelectNormalText
  | SelectLargeText

type alias Model =
  { palette: Palette
  , isEditing: Bool
  , isLargeText: Bool
  , lastPalette: Palette
  }

port updateQs : SerializedPalette -> Cmd msg

port qsUpdated : (SerializedPalette -> msg) -> Sub msg

port updateFavicon : List String -> Cmd msg

defaultPalette : SerializedPalette
defaultPalette =
  [ ("white", "ffffff")
  , ("light", "b3efff")
  , ("bright", "00cfff")
  , ("medium", "046b99")
  , ("dark", "1c304a")
  , ("black", "000000")
  ]

actions : Model -> Html Message
actions model =
  let
    edit =
      [ button [ onClick StartEditing ] [ text "Edit palette" ] ]

    -- TODO: If enter/esc is pressed in a field while editing, it
    -- should have the same effect as pressing the save/cancel buttons.
    -- Well, at least enter should, since it's easily undoable.
    saveOrCancel =
      [ button
        ([ onClick FinishEditing ] ++
          if arePaletteEditsValid model.palette
            then [] else [ disabled True, class "usa-button-disabled" ])
        [ text "Save changes" ]
      , button [ onClick CancelEditing
               , class "usa-button-secondary" ] [ text "Cancel" ]
      ]
  in
    div [ class "usa-grid-full usa-color-row" ]
      (if model.isEditing then saveOrCancel else edit)

view : Model -> Html Message
view model =
  div []
    [ h1 [] [ text "Accessible color palette builder" ]
    , p []
      [ text "This is a tool to help build color palettes that conform with WCAG 2.0 standards."
        , text " For more information, refer to "
        , a [ href "https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html" ] [ text "Success Criterion 1.4.3" ]
        , text "."
      ]
    , h2 [] [ text "Color palette" ]
    , Html.map (\m -> PaletteMessage m)
      (paletteUl model.palette model.isEditing)
    , actions model
    , h2 []
      [ text ("Text size: " ++
        if (model.isLargeText)
          then "large" else "normal")
      ]
    , div [ class "usa-grid-full usa-color-row" ]
      [ button
        ([ onClick SelectNormalText ] ++
          if model.isLargeText
            then [ class "usa-button-disabled" ] else [ disabled True ])
        [ text "Normal Text" ]
      , button
        ([ onClick SelectLargeText ] ++
          if model.isLargeText
            then [ disabled True ] else [ class "usa-button-disabled" ])
        [ text "Large Text" ]
      ]
    , h2 [] [ text "Accessible color combinations" ]
    , matrixDiv model.palette model.isLargeText
    ]

updateFaviconFromPalette : Palette -> Cmd msg
updateFaviconFromPalette palette =
  List.map .color palette
    |> List.map colorToHex
    |> updateFavicon

update : Message -> Model -> (Model, Cmd msg)
update message model =
  case message of
    PaletteMessage msg ->
      let
        newPalette : Palette
        newPalette = updatePalette msg model.palette
      in
        ({model | palette = newPalette}, Cmd.none)
    LoadPalette palette ->
      let
        newPalette : Palette
        newPalette = getPaletteOrDefault palette
      in
        ({model | palette = newPalette
                , isEditing = False},
          updateFaviconFromPalette newPalette)
    StartEditing ->
      ({model | isEditing = True
              , lastPalette = model.palette}, Cmd.none)
    FinishEditing ->
      ({model | isEditing = False},
        Cmd.batch [ updateQs (serializePalette model.palette)
                  , updateFaviconFromPalette model.palette ])
    CancelEditing ->
      ({model | isEditing = False
              , palette = model.lastPalette}, Cmd.none)
    SelectNormalText ->
      ({model | isLargeText = False }, Cmd.none)
    SelectLargeText ->
      ({model | isLargeText = True }, Cmd.none)

getPaletteOrDefault : SerializedPalette -> Palette
getPaletteOrDefault palette =
  if List.length palette == 0
    then deserializePalette defaultPalette
    else deserializePalette palette

init : SerializedPalette -> (Model, Cmd msg)
init qsPalette =
  let
    palette = getPaletteOrDefault qsPalette
  in
    ({ palette = palette
     , isEditing = False
     , isLargeText = False
     , lastPalette = [] },
     updateFaviconFromPalette palette)

subscriptions : Model -> Sub Message
subscriptions model =
  qsUpdated LoadPalette

main =
  Html.programWithFlags
    { init = init
    , subscriptions = subscriptions
    , view = view
    , update = update }
