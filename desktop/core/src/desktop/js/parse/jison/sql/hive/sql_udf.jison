// Licensed to Cloudera, Inc. under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  Cloudera, Inc. licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

NonParenthesizedValueExpressionPrimary
 : ColumnOrArbitraryFunctionRef ArbitraryFunctionRightPart
   {
     // We need to handle arbitrary UDFs here instead of inside UserDefinedFunction or there will be a conflict
     // with columnReference for functions like: db.udf(foo)
     var fn = $1.chain[$1.chain.length - 1].name.toLowerCase();
     $1.lastLoc.type = 'function';
     $1.lastLoc.function = fn;
     $1.lastLoc.location = {
       first_line: $1.lastLoc.location.first_line,
       last_line: $1.lastLoc.location.last_line,
       first_column: $1.lastLoc.location.first_column,
       last_column: $1.lastLoc.location.last_column - 1
     }
     if ($1.lastLoc !== $1.firstLoc) {
        $1.firstLoc.type = 'database';
     } else {
       delete $1.lastLoc.identifierChain;
     }
     if ($2.expression) {
       $$ = { function: fn, expression: $2.expression, types: ['UDFREF'] }
     } else {
       $$ = { function: fn, types: ['UDFREF'] }
     }
   }
 | ArbitraryFunctionName ArbitraryFunctionRightPart
  {
    parser.addFunctionLocation(@1, $1);
    if ($2.expression) {
      $$ = { function: $1, expression: $2.expression, types: ['UDFREF'] }
    } else {
      $$ = { function: $1, types: ['UDFREF'] }
    }
  }
 | UserDefinedFunction
 ;

NonParenthesizedValueExpressionPrimary_EDIT
 : ColumnOrArbitraryFunctionRef ArbitraryFunctionRightPart_EDIT
   {
     var fn = $1.chain[$1.chain.length - 1].name.toLowerCase();
     $1.lastLoc.type = 'function';
     $1.lastLoc.function = fn;
     $1.lastLoc.location = {
       first_line: $1.lastLoc.location.first_line,
       last_line: $1.lastLoc.location.last_line,
       first_column: $1.lastLoc.location.first_column,
       last_column: $1.lastLoc.location.last_column - 1
     }
     if ($1.lastLoc !== $1.firstLoc) {
        $1.firstLoc.type = 'database';
     } else {
       delete $1.lastLoc.identifierChain;
     }
     if ($2.position) {
       parser.applyArgumentTypesToSuggestions(fn, $2.position);
     }
     $$ = { function: fn, types: ['UDFREF'] };
   }
 | ArbitraryFunctionName ArbitraryFunctionRightPart_EDIT
   {
     parser.addFunctionLocation(@1, $1);
     if ($2.position) {
       parser.applyArgumentTypesToSuggestions($1, $2.position);
     }
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | UserDefinedFunction_EDIT
 ;

UserDefinedFunction
 : AggregateFunction OptionalOverClause
   {
     if (!$2) {
       $1.suggestKeywords = ['OVER'];
     }
   }
 | AnalyticFunction OverClause
 | CastFunction
 | ExtractFunction
 ;

UserDefinedFunction_EDIT
 : AggregateFunction_EDIT
 | AggregateFunction OptionalOverClause_EDIT
 | AnalyticFunction_EDIT
 | AnalyticFunction_EDIT OverClause
 | AnalyticFunction 'CURSOR'
   {
     parser.suggestKeywords(['OVER']);
   }
 | AnalyticFunction OverClause_EDIT
 | CastFunction_EDIT
 | ExtractFunction_EDIT
 ;

ArbitraryFunction
 : RegularIdentifier ArbitraryFunctionRightPart
   {
     parser.addFunctionLocation(@1, $1);
     if ($2.expression) {
       $$ = { function: $1, expression: $2.expression, types: ['UDFREF'] }
     } else {
       $$ = { function: $1, types: ['UDFREF'] }
     }
   }
 | ArbitraryFunctionName ArbitraryFunctionRightPart
   {
     parser.addFunctionLocation(@1, $1);
     if ($2.expression) {
       $$ = { function: $1, expression: $2.expression, types: ['UDFREF'] }
     } else {
       $$ = { function: $1, types: ['UDFREF'] }
     }
   }
 ;

ArbitraryFunction_EDIT
 : RegularIdentifier ArbitraryFunctionRightPart_EDIT
   {
     parser.addFunctionLocation(@1, $1);
     if ($2.position) {
       parser.applyArgumentTypesToSuggestions($1, $2.position);
     }
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | ArbitraryFunctionName ArbitraryFunctionRightPart_EDIT
   {
     parser.addFunctionLocation(@1, $1);
     if ($2.position) {
       parser.applyArgumentTypesToSuggestions($1, $2.position);
     }
     $$ = { function: $1, types: ['UDFREF'] };
   }
 ;

ArbitraryFunctionName
 : 'ARRAY'
 | 'BINARY'
 | 'IF'
 | 'MAP'
 | 'TRUNCATE'
 ;

ArbitraryFunctionRightPart
 : '(' ')'
 | '(' ValueExpressionList ')'  -> { expression: $2 }
 ;

ArbitraryFunctionRightPart_EDIT
 : '(' AnyCursor RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     $$ = { position: 1 }
   }
 | '(' ValueExpressionList 'CURSOR' RightParenthesisOrError
   {
     parser.suggestValueExpressionKeywords($3);
   }
 | '(' ValueExpressionList_EDIT RightParenthesisOrError      -> $2
 ;

AggregateFunction
 : CountFunction
 | SumFunction
 | OtherAggregateFunction
 ;

AggregateFunction_EDIT
 : CountFunction_EDIT
 | SumFunction_EDIT
 | OtherAggregateFunction_EDIT
 ;

AnalyticFunction
 : 'ANALYTIC' '(' ')'                      -> { function: $1, types: ['UDFREF'] }
 | 'ANALYTIC' '(' ValueExpressionList ')'  -> { function: $1, expression: $2, types: ['UDFREF'] }
 ;

AnalyticFunction_EDIT
 : 'ANALYTIC' '(' AnyCursor RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     parser.applyArgumentTypesToSuggestions($1, 1);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | 'ANALYTIC' '(' ValueExpressionList 'CURSOR' RightParenthesisOrError
   {
     parser.suggestValueExpressionKeywords($3);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | 'ANALYTIC' '(' ValueExpressionList_EDIT RightParenthesisOrError
   {
     parser.applyArgumentTypesToSuggestions($1, $3.position);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 ;

OptionalOverClause
 :
 | OverClause
 ;

OptionalOverClause_EDIT
 : OverClause_EDIT
 ;

OverClause
 : 'OVER' RegularOrBacktickedIdentifier
 | 'OVER' WindowExpression
 ;

OverClause_EDIT
 : 'OVER' WindowExpression_EDIT
 ;

CastFunction
 : 'CAST' '(' ValueExpression 'AS' PrimitiveType ')'  -> { types: [ $5.toUpperCase() ] }
 | 'CAST' '(' ')'                                      -> { types: [ 'T' ] }
 ;

CastFunction_EDIT
 : 'CAST' '(' AnyCursor 'AS' PrimitiveType RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     $$ = { types: [ $5.toUpperCase() ] };
   }
 | 'CAST' '(' AnyCursor 'AS' RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     $$ = { types: [ 'T' ] };
   }
 | 'CAST' '(' AnyCursor RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     $$ = { types: [ 'T' ] };
   }
 | 'CAST' '(' ValueExpression_EDIT 'AS' PrimitiveType RightParenthesisOrError  -> { types: [ $5.toUpperCase() ] }
 | 'CAST' '(' ValueExpression_EDIT 'AS' RightParenthesisOrError                -> { types: [ 'T' ] }
 | 'CAST' '(' ValueExpression_EDIT RightParenthesisOrError                      -> { types: [ 'T' ] }
 | 'CAST' '(' ValueExpression 'CURSOR' PrimitiveType RightParenthesisOrError
   {
     parser.suggestValueExpressionKeywords($3, [{ value: 'AS', weight: 2 }]);
     $$ =  { types: [ $5.toUpperCase() ] };
   }
 | 'CAST' '(' ValueExpression 'CURSOR' RightParenthesisOrError
   {
     parser.suggestValueExpressionKeywords($3, [{ value: 'AS', weight: 2 }]);
     $$ = { types: [ 'T' ] };
   }
 | 'CAST' '(' ValueExpression 'AS' 'CURSOR' RightParenthesisOrError
   {
     parser.suggestKeywords(parser.getTypeKeywords());
     $$ = { types: [ 'T' ] };
   }
 | 'CAST' '(' 'AS' 'CURSOR' RightParenthesisOrError
   {
     parser.suggestKeywords(parser.getTypeKeywords());
     $$ = { types: [ 'T' ] };
   }
 ;

CountFunction
 : 'COUNT' '(' '*' ')'                                        -> { function: $1, types: ['UDFREF'] }
 | 'COUNT' '(' ')'                                            -> { function: $1, types: ['UDFREF'] }
 | 'COUNT' '(' OptionalAllOrDistinct ValueExpressionList ')'  -> { function: $1, types: ['UDFREF'] }
 ;

CountFunction_EDIT
 : 'COUNT' '(' OptionalAllOrDistinct AnyCursor RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     var keywords = parser.getSelectListKeywords();
     if (!$3) {
       keywords.push('DISTINCT');
       if (parser.yy.result.suggestKeywords) {
         keywords = parser.yy.result.suggestKeywords.concat(keywords);
       }
     }
     parser.suggestKeywords(keywords);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | 'COUNT' '(' OptionalAllOrDistinct ValueExpressionList 'CURSOR' RightParenthesisOrError
   {
     parser.suggestValueExpressionKeywords($4);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | 'COUNT' '(' OptionalAllOrDistinct ValueExpressionList_EDIT RightParenthesisOrError
   {
     if ($4.cursorAtStart) {
       var keywords = parser.getSelectListKeywords();
       if (!$3) {
         keywords.push('DISTINCT');
       }
       parser.suggestKeywords(keywords);
     }
     $$ = { function: $1, types: ['UDFREF'] };
   }
 ;

ExtractFunction
 : 'EXTRACT' '(' DateField 'FROM' ValueExpression ')'  -> { types: ['INT', 'INTEGER'] }
 ;

ExtractFunction_EDIT
 : 'EXTRACT' '(' AnyCursor RightParenthesisOrError
   {
     parser.suggestKeywords(['DAY', 'DAYOFWEEK', 'HOUR', 'MINUTE', 'MONTH', 'QUARTER', 'SECOND', 'WEEK', 'YEAR']);
     $$ = { types: ['INT', 'INTEGER'] }
   }
 | 'EXTRACT' '(' DateField 'CURSOR' RightParenthesisOrError
   {
     parser.suggestKeywords(['FROM']);
     $$ = { types: ['INT', 'INTEGER'] }
   }
 | 'EXTRACT' '(' DateField 'FROM' 'CURSOR' RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     $$ = { types: ['INT', 'INTEGER'] }
   }
 | 'EXTRACT' '(' DateField 'FROM' ValueExpression_EDIT RightParenthesisOrError  -> { types: ['INT', 'INTEGER'] }
 | 'EXTRACT' '(' AnyCursor 'FROM' ValueExpression RightParenthesisOrError
   {
      parser.suggestKeywords(['DAY', 'DAYOFWEEK', 'HOUR', 'MINUTE', 'MONTH', 'QUARTER', 'SECOND', 'WEEK', 'YEAR']);
      $$ = { types: ['INT', 'INTEGER'] }
   }
 | 'EXTRACT' '(' DateField 'CURSOR' ValueExpression RightParenthesisOrError
   {
     parser.suggestKeywords(['FROM']);
     $$ = { types: ['INT', 'INTEGER'] }
   }
 ;

DateField
 : 'DAY'
 | 'DAYOFWEEK'
 | 'HOUR'
 | 'MINUTE'
 | 'MONTH'
 | 'QUARTER'
 | 'SECOND'
 | 'WEEK'
 | 'YEAR'
 ;

OtherAggregateFunction
 : OtherAggregateFunction_Type '(' OptionalAllOrDistinct ')'                      -> { function: $1, types: ['UDFREF'] }
 | OtherAggregateFunction_Type '(' OptionalAllOrDistinct ValueExpressionList ')'  -> { function: $1, types: ['UDFREF'] }
 ;

OtherAggregateFunction_EDIT
 : OtherAggregateFunction_Type '(' OptionalAllOrDistinct AnyCursor RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     var keywords = parser.getSelectListKeywords(true);
     if (!$3) {
       if ($1.toLowerCase() === 'group_concat') {
         keywords.push('ALL');
       } else {
         keywords.push('DISTINCT');
       }
     }
     if (parser.yy.result.suggestKeywords) {
       keywords = parser.yy.result.suggestKeywords.concat(keywords);
     }
     parser.suggestKeywords(keywords);
     parser.applyArgumentTypesToSuggestions($1, 1);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | OtherAggregateFunction_Type '(' OptionalAllOrDistinct ValueExpressionList 'CURSOR' RightParenthesisOrError
   {
     parser.suggestValueExpressionKeywords($4);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | OtherAggregateFunction_Type '(' OptionalAllOrDistinct ValueExpressionList_EDIT RightParenthesisOrError
   {
     if ($4.cursorAtStart) {
       var keywords = parser.getSelectListKeywords(true);
       if (!$3) {
         if ($1.toLowerCase() === 'group_concat') {
           keywords.push('ALL');
         } else {
           keywords.push('DISTINCT');
         }
       }
       if (parser.yy.result.suggestKeywords) {
         keywords = parser.yy.result.suggestKeywords.concat(keywords);
       }
       parser.suggestKeywords(keywords);
     }
     if (parser.yy.result.suggestFunctions && !parser.yy.result.suggestFunctions.types) {
       parser.applyArgumentTypesToSuggestions($1, $4.position);
     }
     $$ = { function: $1, types: ['UDFREF'] };
   }
 ;

OtherAggregateFunction_Type
 : 'AVG'
 | 'COLLECT_LIST'
 | 'COLLECT_SET'
 | 'CORR'
 | 'COVAR_POP'
 | 'COVAR_SAMP'
 | 'HISTOGRAM_NUMERIC'
 | 'MAX'
 | 'MIN'
 | 'NTILE'
 | 'PERCENTILE'
 | 'PERCENTILE_APPROX'
 | 'STDDEV_POP'
 | 'STDDEV_SAMP'
 | 'VAR_POP'
 | 'VAR_SAMP'
 | 'VARIANCE'
 ;

SumFunction
 : 'SUM' '(' OptionalAllOrDistinct ValueExpression ')'  -> { function: $1, types: ['UDFREF'] }
 | 'SUM' '(' ')'                                        -> { function: $1, types: ['UDFREF'] }
 ;

SumFunction_EDIT
 : 'SUM' '(' OptionalAllOrDistinct AnyCursor RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     parser.applyArgumentTypesToSuggestions($1, 1);
     var keywords = parser.getSelectListKeywords(true);
     if (!$3) {
       keywords.push('DISTINCT');
     }
     if (parser.yy.result.suggestKeywords) {
       keywords = parser.yy.result.suggestKeywords.concat(keywords);
     }
     parser.suggestKeywords(keywords);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | 'SUM' '(' OptionalAllOrDistinct ValueExpression 'CURSOR' RightParenthesisOrError
   {
     parser.suggestValueExpressionKeywords($4);
     $$ = { function: $1, types: ['UDFREF'] };
   }
 | 'SUM' '(' OptionalAllOrDistinct ValueExpression_EDIT RightParenthesisOrError
   {
     if (parser.yy.result.suggestFunctions && !parser.yy.result.suggestFunctions.types) {
       parser.applyArgumentTypesToSuggestions($1, 1);
     }
     $$ = { function: $1, types: ['UDFREF'] };
   }
 ;
