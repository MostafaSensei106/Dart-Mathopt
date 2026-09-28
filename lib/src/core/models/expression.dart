import 'variable.dart';
import 'constraint.dart';

abstract class Expression {
  Map<Variable, double> get terms;
  double get constant;

  Expression operator +(Object other);
  Expression operator -(Object other);
  Expression operator *(num scalar);

  Constraint operator <=(num rhs) =>
      Constraint(this, ConstraintSense.lessOrEqual, rhs.toDouble());
  Constraint operator >=(num rhs) =>
      Constraint(this, ConstraintSense.greaterOrEqual, rhs.toDouble());
  Constraint operator ==(num rhs) =>
      Constraint(this, ConstraintSense.equal, rhs.toDouble());
}

class LinearExpression implements Expression {
  @override
  final Map<Variable, double> terms;
  @override
  final double constant;

  LinearExpression(this.terms, [this.constant = 0.0]);

  @override
  Expression operator +(Object other) {
    final newTerms = Map<Variable, double>.from(terms);
    double newConstant = constant;

    if (other is Expression) {
      newConstant += other.constant;
      other.terms.forEach((v, coeff) {
        newTerms[v] = (newTerms[v] ?? 0.0) + coeff;
      });
    } else if (other is Variable) {
      newTerms[other] = (newTerms[other] ?? 0.0) + 1.0;
    } else if (other is num) {
      newConstant += other.toDouble();
    }
    return LinearExpression(newTerms, newConstant);
  }

  @override
  Expression operator -(Object other) {
    if (other is num) return this + (-other);
    if (other is Variable) return this + (other * -1.0);
    if (other is Expression) {
      final negated = other.terms.map((k, v) => MapEntry(k, -v));
      return this + LinearExpression(negated, -other.constant);
    }
    throw ArgumentError('Unsupported operand type for subtraction');
  }

  @override
  Expression operator *(num scalar) {
    final scaledTerms = terms.map((k, v) => MapEntry(k, v * scalar.toDouble()));
    return LinearExpression(scaledTerms, constant * scalar.toDouble());
  }
}
