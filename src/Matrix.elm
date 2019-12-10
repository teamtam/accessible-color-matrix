module Matrix exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, scope, style, title)
import Color exposing (white)

import Symbols exposing (symbols, badContrastSvg)
import Accessibility exposing (ariaHidden, role)
import ContrastRatio exposing (
  contrastRatio, areColorsIndistinguishable, humanFriendlyContrastRatio
  )
import Palette exposing (
  Palette, PaletteEntry, paletteEntryHex, squareBgStyle
  )

badContrastLegendText : String -> String
badContrastLegendText contrastRatio = """
  Please don't use these color combinations; they do not meet a color
  contrast ratio of """ ++ contrastRatio ++
  """:1, so they do not conform with the standards of
  Section 508 for body text. This means that some people would have
  difficulty reading the text. Employing accessibility best practices
  improves the user experience for all users.
"""

badContrastText : PaletteEntry -> PaletteEntry -> Float -> String
badContrastText background foreground ratio =
  "Do not use " ++ foreground.name ++ " text on " ++ background.name ++
    " background; it is not 508-compliant, with a contrast ratio of " ++
      (humanFriendlyContrastRatio ratio) ++ "."

goodContrastText : PaletteEntry -> PaletteEntry -> Float -> String
goodContrastText background foreground ratio =
  "The contrast ratio of " ++ foreground.name ++ " on " ++ background.name ++
    " is " ++ (humanFriendlyContrastRatio ratio) ++ "."

legend : String -> Html msg
legend isLargeText =
  div [ class "usa-matrix-legend" ]
    [ badContrastSvg ""
    , p [ class "usa-sr-invisible", ariaHidden True ]
        [ Html.text (badContrastLegendText isLargeText) ]
    ]

capFirst : String -> String
capFirst str =
  (String.toUpper (String.left 1 str)) ++ (String.dropLeft 1 str)

matrixTableHeader : Palette -> Html msg
matrixTableHeader palette =
  let
    fgStyle : PaletteEntry -> List (String, String)
    fgStyle entry =
      [ ("color", paletteEntryHex entry) ] ++
        if areColorsIndistinguishable entry.color white then
          -- https://css-tricks.com/adding-stroke-to-web-text/
          [ ("text-shadow"
            ,"-1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, " ++
             "1px 1px 0 #000") ]
          else []

    headerCell : PaletteEntry -> Html msg
    headerCell entry =
      td [ scope "col" ]
        [ div [ class "usa-matrix-desc" ]
          [ text (capFirst entry.name)
          , text " text"
          , br [] []
          , small [] [ text (paletteEntryHex entry) ]
          ]
        , strong [ class "usa-sr-invisible"
                 , ariaHidden True
                 , style (fgStyle entry) ]
          [ text "Aa" ]
        ]
  in
    thead []
      [ tr []
        ([ td [ scope "col" ] [] ] ++ List.map headerCell palette)
      ]

matrixTableRow : Palette -> Float -> Html msg
matrixTableRow palette requiredRatio =
  let
    rowHeaderCell : PaletteEntry -> Html msg
    rowHeaderCell entry =
      td [ scope "row" ]
        [ div []
          [ div [ class "usa-matrix-square"
                , style (squareBgStyle entry) ] []
          , div [ class "usa-matrix-desc" ]
            [ text (capFirst entry.name)
            , text " background"
            , br [] []
            , small [] [ text (paletteEntryHex entry) ]
            ]
          ]
        ]

    rowComboCell : PaletteEntry -> PaletteEntry -> Html msg
    rowComboCell background foreground =
      let
        ratio : Float
        ratio = contrastRatio background.color foreground.color

        validCell : Html msg
        validCell =
          td [ class "usa-matrix-valid-color-combo" ]
            [ div [ class "usa-matrix-square"
                  , style (squareBgStyle background)
                  , title (goodContrastText background foreground ratio)
                  , role "presentation" ]
                [ strong [ class "usa-sr-invisible"
                         , ariaHidden True
                         , style [("color", paletteEntryHex foreground)] ]
                    [ text "Aa" ]
                ]
            , div [ class "usa-matrix-color-combo-description" ]
              [ strong [] [ text (capFirst foreground.name) ]
              , text " text on "
              , strong [] [ text (capFirst background.name) ]
              , text " background"
              , span [ class "usa-sr-only" ]
                [ text " is 508-compliant, with a contrast ratio of "
                , text (humanFriendlyContrastRatio ratio)
                , text "."
                ]
              ]
            ]

        invalidCell : Html msg
        invalidCell =
          let
            desc = badContrastText background foreground ratio
          in
            td [ class "usa-matrix-invalid-color-combo" ]
              [ div [ role "presentation", title desc ]
                [ badContrastSvg "usa-matrix-square" ]
              , div [ class "usa-sr-only" ] [ text desc ]
              ]
      in
        if ratio >= requiredRatio then validCell else invalidCell

    row : Palette -> PaletteEntry -> Html msg
    row palette background =
      tr []
        ([ rowHeaderCell background ] ++
          List.map (rowComboCell background) palette)
  in
    tbody [] (List.map (row palette) (List.reverse palette))

matrixTable : Palette -> Bool -> Html msg
matrixTable palette isLargeText =
  table [ class "usa-table-borderless usa-matrix" ]
    [ matrixTableHeader palette
    , matrixTableRow palette (if isLargeText then 3 else 4.5)
    ]

matrixDiv : Palette -> Bool -> Html msg
matrixDiv palette isLargeText =
  div []
    [ symbols
    , legend (if isLargeText then "3" else "4.5")
    , matrixTable palette isLargeText
    ]
